using System.Text.Json.Nodes;
using SolidCraftAgent.Mcp.Tools;

namespace SolidCraftAgent.Mcp;

/// <summary>
/// Bridges LLM tool calls to the SolidCraft MCP client and formats kernel errors for chat.
/// </summary>
public sealed class McpToolBridge
{
    private readonly SolidCraftMcpClient _client;

    public McpToolBridge(SolidCraftMcpClient client)
    {
        _client = client;
    }

    public IReadOnlyList<(string Name, string Description, JsonNode? Schema)> GetLlmToolDefinitions()
    {
        if (_client.Tools.Count == 0)
        {
            return SolidCraftToolNames.CoreTools
                .Select(name => (name, $"SolidCraft tool '{name}'", (JsonNode?)new JsonObject
                {
                    ["type"] = "object",
                    ["properties"] = new JsonObject(),
                }))
                .ToList();
        }

        return _client.Tools
            .Select(t => (t.Name, t.Description ?? $"SolidCraft tool '{t.Name}'", t.InputSchema))
            .ToList();
    }

    public async Task<string> InvokeFromLlmAsync(
        string toolName,
        string argumentsJson,
        CancellationToken cancellationToken = default)
    {
        JsonNode? args;
        try
        {
            args = string.IsNullOrWhiteSpace(argumentsJson)
                ? new JsonObject()
                : JsonNode.Parse(argumentsJson);
        }
        catch (Exception ex)
        {
            return $"Tool argument JSON was invalid: {ex.Message}";
        }

        try
        {
            var result = await _client.CallToolAsync(toolName, args, cancellationToken).ConfigureAwait(false);
            return string.IsNullOrWhiteSpace(result.Content)
                ? $"Tool '{toolName}' completed with no content."
                : result.Content;
        }
        catch (McpBatchException ex)
        {
            return FormatKernelError("batch (all-or-nothing; rolled back)", ex);
        }
        catch (McpKernelException ex)
        {
            return FormatKernelError(ex.ToolName ?? toolName, ex);
        }
        catch (Exception ex)
        {
            return $"Unexpected MCP failure for '{toolName}': {ex.Message}";
        }
    }

    private static string FormatKernelError(string toolName, McpKernelException ex)
    {
        var raw = string.IsNullOrWhiteSpace(ex.Raw) ? string.Empty : $"\nRaw: {ex.Raw}";
        return $"SolidCraft kernel error in '{toolName}': {ex.Message}{raw}\nRetry with a corrected tool call or workaround.";
    }
}
