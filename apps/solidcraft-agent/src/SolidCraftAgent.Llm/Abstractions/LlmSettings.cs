namespace SolidCraftAgent.Llm.Abstractions;

/// <summary>
/// LLM settings aligned with SolidCraft's built-in "Add agent" API-endpoint form:
/// protocol (Anthropic-compatible vs OpenAI-compatible), base URL, model, timeout, keychain API key.
/// </summary>
public sealed class LlmSettings
{
    public LlmProviderKind Provider { get; set; } = LlmProviderKind.Claude;

    /// <summary>Display name for the active agent entry (mirrors SolidCraft "Name").</summary>
    public string AgentName { get; set; } = "Anthropic";

    public string ClaudeModel { get; set; } = "claude-sonnet-4-5";

    public string OpenAiModel { get; set; } = "gpt-4.1";

    public string OpenAiCompatibleModel { get; set; } = "llama3.1";

    /// <summary>
    /// Anthropic-compatible base URL as shown in SolidCraft (includes /v1).
    /// Messages are posted to {base}/messages.
    /// </summary>
    public string ClaudeBaseUrl { get; set; } = "https://api.anthropic.com/v1";

    public string OpenAiBaseUrl { get; set; } = "https://api.openai.com/v1";

    /// <summary>Base URL for OpenAI-compatible local servers (Ollama, LM Studio).</summary>
    public string OpenAiCompatibleBaseUrl { get; set; } = "http://127.0.0.1:11434/v1";

    /// <summary>Request timeout in seconds (SolidCraft default is 300).</summary>
    public int RequestTimeoutSeconds { get; set; } = 300;

    public string ActiveModelId => Provider switch
    {
        LlmProviderKind.Claude => ClaudeModel,
        LlmProviderKind.OpenAi => OpenAiModel,
        LlmProviderKind.OpenAiCompatible => OpenAiCompatibleModel,
        _ => ClaudeModel,
    };

    public string ActiveBaseUrl => Provider switch
    {
        LlmProviderKind.Claude => ClaudeBaseUrl,
        LlmProviderKind.OpenAi => OpenAiBaseUrl,
        LlmProviderKind.OpenAiCompatible => OpenAiCompatibleBaseUrl,
        _ => ClaudeBaseUrl,
    };
}
