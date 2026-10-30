using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization;

namespace SolidCraftAgent.Mcp.JsonRpc;

public sealed class JsonRpcRequest
{
    [JsonPropertyName("jsonrpc")]
    public string JsonRpc { get; set; } = "2.0";

    [JsonPropertyName("id")]
    public JsonNode? Id { get; set; }

    [JsonPropertyName("method")]
    public string Method { get; set; } = string.Empty;

    [JsonPropertyName("params")]
    public JsonNode? Params { get; set; }
}

public sealed class JsonRpcResponse
{
    [JsonPropertyName("jsonrpc")]
    public string JsonRpc { get; set; } = "2.0";

    [JsonPropertyName("id")]
    public JsonNode? Id { get; set; }

    [JsonPropertyName("result")]
    public JsonNode? Result { get; set; }

    [JsonPropertyName("error")]
    public JsonRpcError? Error { get; set; }
}

public sealed class JsonRpcError
{
    [JsonPropertyName("code")]
    public int Code { get; set; }

    [JsonPropertyName("message")]
    public string Message { get; set; } = string.Empty;

    [JsonPropertyName("data")]
    public JsonNode? Data { get; set; }
}

public sealed class JsonRpcNotification
{
    [JsonPropertyName("jsonrpc")]
    public string JsonRpc { get; set; } = "2.0";

    [JsonPropertyName("method")]
    public string Method { get; set; } = string.Empty;

    [JsonPropertyName("params")]
    public JsonNode? Params { get; set; }
}

public static class JsonRpcSerializer
{
    public static readonly JsonSerializerOptions Options = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        WriteIndented = false,
    };

    public static string SerializeRequest(JsonRpcRequest request) =>
        JsonSerializer.Serialize(request, Options);

    public static string SerializeNotification(JsonRpcNotification notification) =>
        JsonSerializer.Serialize(notification, Options);

    public static JsonRpcResponse DeserializeResponse(string json) =>
        JsonSerializer.Deserialize<JsonRpcResponse>(json, Options)
        ?? throw new InvalidOperationException("Failed to deserialize JSON-RPC response.");
}
