using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using SolidCraftAgent.Llm.Abstractions;
using SolidCraftAgent.Secrets;

namespace SolidCraftAgent.Llm.Providers;

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

    public ClaudeChatProvider(HttpClient http, ISecretStore secrets, string modelId, string baseUrl)
    {
        _http = http;
        _secrets = secrets;
        ModelId = modelId;
        _baseUrl = baseUrl.TrimEnd('/');
    }

    public LlmProviderKind Kind => LlmProviderKind.Claude;

    public string ModelId { get; }

    public async Task<ChatResponse> CompleteAsync(ChatRequest request, CancellationToken cancellationToken = default)
    {
        var apiKey = await _secrets.GetAsync(SecretKeys.ClaudeApiKey, cancellationToken).ConfigureAwait(false);
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException($"Claude API key is not configured (secret '{SecretKeys.ClaudeApiKey}').");
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

        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, $"{_baseUrl}/v1/messages");
        httpRequest.Headers.Add("x-api-key", apiKey);
        httpRequest.Headers.Add("anthropic-version", "2023-06-01");
        httpRequest.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        httpRequest.Content = new StringContent(body.ToJsonString(JsonOptions), Encoding.UTF8, "application/json");

        using var response = await _http.SendAsync(httpRequest, cancellationToken).ConfigureAwait(false);
        var raw = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"Claude chat failed ({(int)response.StatusCode}): {raw}");
        }

        return ParseResponse(raw);
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
