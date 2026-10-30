using System.Text.Json.Nodes;

namespace SolidCraftAgent.Mcp.Tools;

public sealed record McpToolDescriptor(string Name, string? Description, JsonNode? InputSchema);

public sealed record McpToolCallResult(bool IsError, string Content, JsonNode? StructuredContent = null);

public class McpKernelException : Exception
{
    public McpKernelException(string message, string? toolName = null, string? raw = null)
        : base(message)
    {
        ToolName = toolName;
        Raw = raw;
    }

    public string? ToolName { get; }

    public string? Raw { get; }
}

public class McpBatchException : McpKernelException
{
    public McpBatchException(string message, string? raw = null)
        : base(message, SolidCraftToolNames.Batch, raw)
    {
    }
}
