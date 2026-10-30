using System.Text;
using System.Text.Json.Nodes;
using SolidCraftAgent.Core.Config;
using SolidCraftAgent.Core.Lessons;
using SolidCraftAgent.Core.Seed;
using SolidCraftAgent.Llm;
using SolidCraftAgent.Llm.Abstractions;
using SolidCraftAgent.Mcp;
using SolidCraftAgent.Mcp.Tools;

namespace SolidCraftAgent.Core.Agent;

/// <summary>
/// Build + verify orchestrator: read lessons → list dims → state readings → MCP tools →
/// verify → save → report inferences; on correction diagnose → fix → pending lesson.
/// </summary>
public sealed class AgentOrchestrator
{
    private readonly AppSettings _settings;
    private readonly ILessonStore _lessons;
    private readonly SystemPromptBuilder _promptBuilder;
    private readonly IChatProviderFactory _chatFactory;
    private readonly Func<CancellationToken, Task<SolidCraftMcpClient>> _mcpFactory;
    private readonly int _maxToolRounds;

    public AgentOrchestrator(
        AppSettings settings,
        ILessonStore lessons,
        SystemPromptBuilder promptBuilder,
        IChatProviderFactory chatFactory,
        Func<CancellationToken, Task<SolidCraftMcpClient>> mcpFactory,
        int maxToolRounds = 12)
    {
        _settings = settings;
        _lessons = lessons;
        _promptBuilder = promptBuilder;
        _chatFactory = chatFactory;
        _mcpFactory = mcpFactory;
        _maxToolRounds = maxToolRounds;
    }

    public SessionTranscript Transcript { get; } = new();

    public event EventHandler<AgentStep>? StepEmitted;

    public async Task<string> RunUserTurnAsync(string userMessage, CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(userMessage);
        await _lessons.EnsureSeededAsync(cancellationToken).ConfigureAwait(false);

        Transcript.AddUserMessage(ComposeUserPayload(userMessage));
        Emit(AgentStepKind.Info, "Starting agent turn");

        var systemPrompt = await _promptBuilder.BuildAsync(cancellationToken).ConfigureAwait(false);
        systemPrompt = AppendWorkflowChecklist(systemPrompt);

        var provider = _chatFactory.Create(_settings.Llm);
        Emit(AgentStepKind.Info, $"LLM provider: {provider.Kind} / {provider.ModelId}");

        await using var mcp = await _mcpFactory(cancellationToken).ConfigureAwait(false);
        var bridge = new McpToolBridge(mcp);
        var tools = bridge.GetLlmToolDefinitions()
            .Select(t => new ToolDefinition(t.Name, t.Description, t.Schema))
            .ToList();

        // Ensure units/new_design awareness is always in the first tool surface.
        EnsureCoreToolsPresent(tools);

        string? finalAssistantText = null;
        for (var round = 0; round < _maxToolRounds; round++)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var request = new ChatRequest(Transcript.Messages.ToList(), systemPrompt, tools);
            ChatResponse response;
            try
            {
                response = await provider.CompleteAsync(request, cancellationToken).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                Emit(AgentStepKind.Error, $"LLM error: {ex.Message}");
                throw;
            }

            Transcript.AddAssistantMessage(response.Content, response.ToolCalls);
            Emit(AgentStepKind.Llm, string.IsNullOrWhiteSpace(response.Content) ? "(tool planning)" : Truncate(response.Content, 240));

            if (response.ToolCalls.Count == 0)
            {
                finalAssistantText = response.Content;
                break;
            }

            foreach (var call in response.ToolCalls)
            {
                Emit(AgentStepKind.Tool, $"Calling {call.Name}", call.ArgumentsJson);
                var toolResult = await bridge.InvokeFromLlmAsync(call.Name, call.ArgumentsJson, cancellationToken)
                    .ConfigureAwait(false);
                Transcript.AddToolResult(call.Id, toolResult);

                if (toolResult.Contains("kernel error", StringComparison.OrdinalIgnoreCase)
                    || toolResult.Contains("Batch failed", StringComparison.OrdinalIgnoreCase))
                {
                    Emit(AgentStepKind.Error, toolResult);
                }
                else
                {
                    Emit(AgentStepKind.Tool, Truncate(toolResult, 240));
                }

                if (string.Equals(call.Name, SolidCraftToolNames.Save, StringComparison.OrdinalIgnoreCase))
                {
                    TryCaptureSavePath(call.ArgumentsJson);
                }

                if (string.Equals(call.Name, SolidCraftToolNames.NewDesign, StringComparison.OrdinalIgnoreCase))
                {
                    // Soft reminder step: units must follow new_design.
                    Emit(AgentStepKind.Verify, "Check: document.units mm must follow new_design (L001).");
                }
            }
        }

        finalAssistantText ??= "Stopped after the maximum tool-call rounds. Review the step log and continue.";

        if (LooksLikeCorrection(userMessage))
        {
            await HandleCorrectionAsync(userMessage, finalAssistantText, cancellationToken).ConfigureAwait(false);
        }

        Emit(AgentStepKind.Info, "Agent turn complete");
        return finalAssistantText;
    }

    /// <summary>
    /// Deterministic preflight used by tests and by the UI before an LLM turn:
    /// lessons loaded, units rule present, bevel math available.
    /// </summary>
    public async Task<IReadOnlyList<string>> RunPreflightChecksAsync(CancellationToken cancellationToken = default)
    {
        await _lessons.EnsureSeededAsync(cancellationToken).ConfigureAwait(false);
        var findings = new List<string>();
        var active = await _lessons.BuildActiveLessonsPromptSectionAsync(cancellationToken).ConfigureAwait(false);
        if (!active.Contains("L001", StringComparison.Ordinal))
        {
            findings.Add("Missing seed lesson L001 (units mm after new_design).");
        }

        if (!active.Contains("L002", StringComparison.Ordinal))
        {
            findings.Add("Missing seed lesson L002 (thickness mapping).");
        }

        if (!active.Contains("L003", StringComparison.Ordinal))
        {
            findings.Add("Missing seed lesson L003 (compound callouts / bevel math).");
        }

        var bevel = VerificationMath.ComputeBevel(0.5, 60, 1.0);
        if (Math.Abs(bevel.Depth - 0.8660254037844386) > 1e-9)
        {
            findings.Add("Bevel depth math drifted from the seeded C32057-51 expectation.");
        }

        if (string.IsNullOrWhiteSpace(_settings.PermanentModelsFolder))
        {
            findings.Add("Permanent models folder is not configured.");
        }

        if (findings.Count == 0)
        {
            findings.Add("Preflight OK: lessons, bevel math, and save folder configured.");
        }

        foreach (var finding in findings)
        {
            Emit(AgentStepKind.Verify, finding);
        }

        return findings;
    }

    private async Task HandleCorrectionAsync(string userMessage, string assistantText, CancellationToken cancellationToken)
    {
        Emit(AgentStepKind.Lesson, "User correction detected; drafting a pending lesson.");
        var title = "Correction: " + Truncate(userMessage.Replace('\n', ' '), 80);
        var body = new StringBuilder()
            .AppendLine("Diagnose the root cause, fix and re-verify, then keep this lesson general.")
            .AppendLine("User correction:")
            .AppendLine(userMessage.Trim())
            .AppendLine()
            .AppendLine("Agent response summary:")
            .AppendLine(Truncate(assistantText, 500))
            .ToString();

        var lesson = await _lessons.AppendPendingAsync(title, body, source: "correction", cancellationToken)
            .ConfigureAwait(false);
        Emit(AgentStepKind.Lesson, $"Pending lesson {lesson.Id} created (approve in Lessons UI).");
    }

    private string ComposeUserPayload(string userMessage)
    {
        if (Transcript.DrawingPaths.Count == 0)
        {
            return userMessage;
        }

        var drawings = string.Join(Environment.NewLine, Transcript.DrawingPaths.Select(p => $"- {p}"));
        return $"""
Attached drawings:
{drawings}

Permanent save folder: {_settings.PermanentModelsFolder}
Default units: {_settings.DefaultUnits}

User request:
{userMessage}
""";
    }

    private static string AppendWorkflowChecklist(string systemPrompt) =>
        systemPrompt + """

## Orchestrator checklist (this turn)
1. Read active lessons first.
2. List every dimension.
3. State each reading (measured vs inferred).
4. Call MCP tools (prefer batch; all-or-nothing).
5. Verify dimensions (mirrored both sides; bevel W×A° math; thickness mapping).
6. Save to the permanent models folder.
7. Report inferences.
On correction: diagnose → fix → pending lesson.
""";

    private static void EnsureCoreToolsPresent(List<ToolDefinition> tools)
    {
        foreach (var name in SolidCraftToolNames.CoreTools)
        {
            if (tools.Any(t => string.Equals(t.Name, name, StringComparison.Ordinal)))
            {
                continue;
            }

            tools.Add(new ToolDefinition(
                name,
                $"SolidCraft tool '{name}'",
                new JsonObject { ["type"] = "object", ["properties"] = new JsonObject() }));
        }
    }

    private void TryCaptureSavePath(string argumentsJson)
    {
        try
        {
            var node = JsonNode.Parse(argumentsJson);
            var path = node?["path"]?.GetValue<string>();
            if (!string.IsNullOrWhiteSpace(path))
            {
                Transcript.LastSavedModelPath = path;
                Emit(AgentStepKind.Save, $"Saved model path: {path}");
            }
        }
        catch
        {
            // Ignore malformed save args; bridge already reported errors.
        }
    }

    private static bool LooksLikeCorrection(string userMessage)
    {
        var text = userMessage.ToLowerInvariant();
        return text.Contains("wrong", StringComparison.Ordinal)
            || text.Contains("incorrect", StringComparison.Ordinal)
            || text.Contains("reverse", StringComparison.Ordinal)
            || text.Contains("fix it", StringComparison.Ordinal)
            || text.Contains("should be", StringComparison.Ordinal)
            || text.Contains("not the", StringComparison.Ordinal)
            || text.Contains("measures", StringComparison.Ordinal);
    }

    private void Emit(AgentStepKind kind, string message, string? detail = null)
    {
        var step = new AgentStep(kind, message, DateTimeOffset.UtcNow, detail);
        Transcript.AddStep(kind, message, detail);
        StepEmitted?.Invoke(this, step);
    }

    private static string Truncate(string value, int max) =>
        value.Length <= max ? value : value[..(max - 3)] + "...";
}
