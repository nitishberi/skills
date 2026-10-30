using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using SolidCraftAgent.Llm.Abstractions;
using SolidCraftAgent.Secrets;

namespace SolidCraftAgent.Llm.Providers;

/// <summary>
/// Anthropic Messages API (also used for Anthropic-compatible local / proxy endpoints).
/// Matches SolidCraft's "Anthropic-compatible API" agent kind: base URL like
/// https://api.anthropic.com/v1, optional keychain API key, arbitrary model id.
/// </summary>
public sealed class ClaudeChatProvider : IChatProvider
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull,
    };

    private readonly HttpClient _http;
    private readonly ISecretStore _secrets;
    private readonly string _baseUrl;
    private readonly bool _requireApiKey;
    private readonly TimeSpan _timeout;

    public ClaudeChatProvider(
        HttpClient http,
        ISecretStore secrets,
        string modelId,
        string baseUrl,
        bool requireApiKey = false,
        int requestTimeoutSeconds = 300)
    {
        _http = http;
        _secrets = secrets;
        ModelId = modelId;
        _baseUrl = NormalizeBaseUrl(baseUrl);
        _requireApiKey = requireApiKey;
        _timeout = TimeSpan.FromSeconds(requestTimeoutSeconds <= 0 ? 300 : requestTimeoutSeconds);
    }

    public LlmProviderKind Kind => LlmProviderKind.Claude;

    public string ModelId { get; }

    public string MessagesUrl => $"{_baseUrl}/messages";

    public async Task<ChatResponse> CompleteAsync(ChatRequest request, CancellationToken cancellationToken = default)
    {
        var apiKey = await _secrets.GetAsync(SecretKeys.ClaudeApiKey, cancellationToken).ConfigureAwait(false);
        if (_requireApiKey && string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException(
                $"Anthropic API key is not configured (secret '{SecretKeys.ClaudeApiKey}'). Leave empty only for a local Anthropic-compatible server.");
        }

        var messages = new JsonArray();
        foreach (var message in request.Messages)
        {
            if (message.Role is "tool")
            {
                messages.Add(new JsonObject
                {
                    ["role"] = "user",
                    ["content"] = new JsonArray
                    {
                        new JsonObject
                        {
                            ["type"] = "tool_result",
                            ["tool_use_id"] = message.ToolCallId ?? string.Empty,
                            ["content"] = message.Content,
                        },
                    },
                });
                continue;
            }

            if (message.ToolCalls is { Count: > 0 })
            {
                var content = new JsonArray();
                if (!string.IsNullOrWhiteSpace(message.Content))
                {
                    content.Add(new JsonObject { ["type"] = "text", ["text"] = message.Content });
                }

                foreach (var call in message.ToolCalls)
                {
                    JsonNode input;
                    try
                    {
                        input = JsonNode.Parse(call.ArgumentsJson) ?? new JsonObject();
                    }
                    catch (JsonException)
                    {
                        input = new JsonObject();
                    }

                    content.Add(new JsonObject
                    {
                        ["type"] = "tool_use",
                        ["id"] = call.Id,
                        ["name"] = call.Name,
                        ["input"] = input,
                    });
                }

                messages.Add(new JsonObject
                {
                    ["role"] = "assistant",
                    ["content"] = content,
                });
                continue;
            }

            messages.Add(new JsonObject
            {
                ["role"] = message.Role == "assistant" ? "assistant" : "user",
                ["content"] = message.Content,
            });
        }

        var body = new JsonObject
        {
            ["model"] = ModelId,
            ["max_tokens"] = request.MaxTokens ?? 4096,
            ["temperature"] = request.Temperature,
            ["messages"] = messages,
        };
        if (!string.IsNullOrWhiteSpace(request.SystemPrompt))
        {
            body["system"] = request.SystemPrompt;
        }

        if (request.Tools is { Count: > 0 })
        {
            var tools = new JsonArray();
            foreach (var tool in request.Tools)
            {
                tools.Add(new JsonObject
                {
                    ["name"] = tool.Name,
                    ["description"] = tool.Description,
                    ["input_schema"] = tool.ParametersSchema?.DeepClone() ?? new JsonObject
                    {
                        ["type"] = "object",
                        ["properties"] = new JsonObject(),
                    },
                });
            }

            body["tools"] = tools;
        }

        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(_timeout);

        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, MessagesUrl);
        if (!string.IsNullOrWhiteSpace(apiKey))
        {
            httpRequest.Headers.Add("x-api-key", apiKey);
        }

        httpRequest.Headers.Add("anthropic-version", "2023-06-01");
        httpRequest.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        httpRequest.Content = new StringContent(body.ToJsonString(JsonOptions), Encoding.UTF8, "application/json");

        using var response = await _http.SendAsync(httpRequest, timeoutCts.Token).ConfigureAwait(false);
        var raw = await response.Content.ReadAsStringAsync(timeoutCts.Token).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"Anthropic-compatible chat failed ({(int)response.StatusCode}): {raw}");
        }

        return ParseResponse(raw);
    }

    /// <summary>
    /// SolidCraft stores base URL as https://api.anthropic.com/v1.
    /// Older configs may omit /v1; normalize so we always POST to {base}/messages.
    /// </summary>
    internal static string NormalizeBaseUrl(string baseUrl)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(baseUrl);
        var trimmed = baseUrl.Trim().TrimEnd('/');
        if (trimmed.EndsWith("/v1", StringComparison.OrdinalIgnoreCase))
        {
            return trimmed;
        }

        return trimmed + "/v1";
    }

    internal static ChatResponse ParseResponse(string raw)
    {
        using var doc = JsonDocument.Parse(raw);
        var root = doc.RootElement;
        var contentParts = root.GetProperty("content");
        var text = new StringBuilder();
        var toolCalls = new List<ToolCall>();

        foreach (var part in contentParts.EnumerateArray())
        {
            var type = part.GetProperty("type").GetString();
            if (type == "text")
            {
                text.Append(part.GetProperty("text").GetString());
            }
            else if (type == "tool_use")
            {
                var id = part.GetProperty("id").GetString() ?? Guid.NewGuid().ToString("N");
                var name = part.GetProperty("name").GetString() ?? string.Empty;
                var input = part.GetProperty("input").GetRawText();
                toolCalls.Add(new ToolCall(id, name, input));
            }
        }

        var stop = root.TryGetProperty("stop_reason", out var stopEl) ? stopEl.GetString() : null;
        return new ChatResponse(text.ToString(), toolCalls, stop, raw);
    }
}
