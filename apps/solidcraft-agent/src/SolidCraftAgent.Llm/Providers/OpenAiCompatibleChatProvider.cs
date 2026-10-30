using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using SolidCraftAgent.Llm.Abstractions;
using SolidCraftAgent.Secrets;

namespace SolidCraftAgent.Llm.Providers;

/// <summary>
/// OpenAI Chat Completions API, also used for local OpenAI-compatible endpoints
/// (Ollama / LM Studio) by changing the base URL.
/// </summary>
public sealed class OpenAiCompatibleChatProvider : IChatProvider
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull,
    };

    private readonly HttpClient _http;
    private readonly ISecretStore _secrets;
    private readonly string _apiKeySecretKey;
    private readonly bool _requireApiKey;

    public OpenAiCompatibleChatProvider(
        HttpClient http,
        ISecretStore secrets,
        LlmProviderKind kind,
        string modelId,
        string baseUrl,
        string apiKeySecretKey,
        bool requireApiKey = true)
    {
        _http = http;
        _secrets = secrets;
        Kind = kind;
        ModelId = modelId;
        BaseUrl = baseUrl.TrimEnd('/');
        _apiKeySecretKey = apiKeySecretKey;
        _requireApiKey = requireApiKey;
    }

    public LlmProviderKind Kind { get; }

    public string ModelId { get; }

    public string BaseUrl { get; }

    public async Task<ChatResponse> CompleteAsync(ChatRequest request, CancellationToken cancellationToken = default)
    {
        var apiKey = await _secrets.GetAsync(_apiKeySecretKey, cancellationToken).ConfigureAwait(false);
        if (_requireApiKey && string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException($"API key for {Kind} is not configured (secret '{_apiKeySecretKey}').");
        }

        var messages = new JsonArray();
        if (!string.IsNullOrWhiteSpace(request.SystemPrompt))
        {
            messages.Add(new JsonObject
            {
                ["role"] = "system",
                ["content"] = request.SystemPrompt,
            });
        }

        foreach (var message in request.Messages)
        {
            var node = new JsonObject
            {
                ["role"] = message.Role,
                ["content"] = message.Content,
            };
            if (!string.IsNullOrEmpty(message.ToolCallId))
            {
                node["tool_call_id"] = message.ToolCallId;
            }

            if (message.ToolCalls is { Count: > 0 })
            {
                var calls = new JsonArray();
                foreach (var call in message.ToolCalls)
                {
                    calls.Add(new JsonObject
                    {
                        ["id"] = call.Id,
                        ["type"] = "function",
                        ["function"] = new JsonObject
                        {
                            ["name"] = call.Name,
                            ["arguments"] = call.ArgumentsJson,
                        },
                    });
                }

                node["tool_calls"] = calls;
            }

            messages.Add(node);
        }

        var body = new JsonObject
        {
            ["model"] = ModelId,
            ["messages"] = messages,
            ["temperature"] = request.Temperature,
        };
        if (request.MaxTokens is int maxTokens)
        {
            body["max_tokens"] = maxTokens;
        }

        if (request.Tools is { Count: > 0 })
        {
            var tools = new JsonArray();
            foreach (var tool in request.Tools)
            {
                tools.Add(new JsonObject
                {
                    ["type"] = "function",
                    ["function"] = new JsonObject
                    {
                        ["name"] = tool.Name,
                        ["description"] = tool.Description,
                        ["parameters"] = tool.ParametersSchema?.DeepClone() ?? new JsonObject { ["type"] = "object" },
                    },
                });
            }

            body["tools"] = tools;
            body["tool_choice"] = "auto";
        }

        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, $"{BaseUrl}/chat/completions");
        if (!string.IsNullOrWhiteSpace(apiKey))
        {
            httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        }

        httpRequest.Content = new StringContent(body.ToJsonString(JsonOptions), Encoding.UTF8, "application/json");

        using var response = await _http.SendAsync(httpRequest, cancellationToken).ConfigureAwait(false);
        var raw = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"OpenAI-compatible chat failed ({(int)response.StatusCode}): {raw}");
        }

        return ParseResponse(raw);
    }

    internal static ChatResponse ParseResponse(string raw)
    {
        using var doc = JsonDocument.Parse(raw);
        var root = doc.RootElement;
        var choice = root.GetProperty("choices")[0];
        var message = choice.GetProperty("message");
        var content = message.TryGetProperty("content", out var contentEl) && contentEl.ValueKind == JsonValueKind.String
            ? contentEl.GetString() ?? string.Empty
            : string.Empty;
        var finish = choice.TryGetProperty("finish_reason", out var finishEl) ? finishEl.GetString() : null;

        var toolCalls = new List<ToolCall>();
        if (message.TryGetProperty("tool_calls", out var toolCallsEl) && toolCallsEl.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in toolCallsEl.EnumerateArray())
            {
                var id = item.GetProperty("id").GetString() ?? Guid.NewGuid().ToString("N");
                var function = item.GetProperty("function");
                var name = function.GetProperty("name").GetString() ?? string.Empty;
                var args = function.TryGetProperty("arguments", out var argsEl) ? argsEl.GetString() ?? "{}" : "{}";
                toolCalls.Add(new ToolCall(id, name, args));
            }
        }

        return new ChatResponse(content, toolCalls, finish, raw);
    }
}
