using System.Text.Json.Nodes;

namespace SolidCraftAgent.Llm.Abstractions;

public sealed record ChatMessage(string Role, string Content, IReadOnlyList<ToolCall>? ToolCalls = null, string? ToolCallId = null);

public sealed record ToolCall(string Id, string Name, string ArgumentsJson);

public sealed record ToolDefinition(string Name, string Description, JsonNode? ParametersSchema);

public sealed record ChatRequest(
    IReadOnlyList<ChatMessage> Messages,
    string? SystemPrompt = null,
    IReadOnlyList<ToolDefinition>? Tools = null,
    double Temperature = 0.2,
    int? MaxTokens = 4096);

public sealed record ChatResponse(
    string Content,
    IReadOnlyList<ToolCall> ToolCalls,
    string? FinishReason = null,
    string? RawJson = null);
