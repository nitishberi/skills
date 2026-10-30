using System.Text.Json;
using SolidCraftAgent.Llm.Abstractions;

namespace SolidCraftAgent.Core.Agent;

public sealed class SessionTranscript
{
    private readonly List<ChatMessage> _messages = [];
    private readonly List<AgentStep> _steps = [];
    private readonly List<string> _drawingPaths = [];

    public IReadOnlyList<ChatMessage> Messages => _messages;

    public IReadOnlyList<AgentStep> Steps => _steps;

    public IReadOnlyList<string> DrawingPaths => _drawingPaths;

    public string? LastSavedModelPath { get; set; }

    public void AttachDrawing(string path)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(path);
        _drawingPaths.Add(path);
    }

    public void AddUserMessage(string content)
    {
        _messages.Add(new ChatMessage("user", content));
    }

    public void AddAssistantMessage(string content, IReadOnlyList<ToolCall>? toolCalls = null)
    {
        _messages.Add(new ChatMessage("assistant", content, toolCalls));
    }

    public void AddToolResult(string toolCallId, string content)
    {
        _messages.Add(new ChatMessage("tool", content, ToolCallId: toolCallId));
    }

    public void AddStep(AgentStepKind kind, string message, string? detail = null) =>
        _steps.Add(new AgentStep(kind, message, DateTimeOffset.UtcNow, detail));

    public async Task SaveAsync(string path, CancellationToken cancellationToken = default)
    {
        var dir = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(dir))
        {
            Directory.CreateDirectory(dir);
        }

        var payload = new
        {
            drawingPaths = _drawingPaths,
            lastSavedModelPath = LastSavedModelPath,
            messages = _messages,
            steps = _steps,
        };
        await using var stream = File.Create(path);
        await JsonSerializer.SerializeAsync(stream, payload, new JsonSerializerOptions { WriteIndented = true }, cancellationToken)
            .ConfigureAwait(false);
    }
}
