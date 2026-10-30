namespace SolidCraftAgent.Llm.Abstractions;

public sealed class LlmSettings
{
    public LlmProviderKind Provider { get; set; } = LlmProviderKind.Claude;

    public string ClaudeModel { get; set; } = "claude-sonnet-4-5";

    public string OpenAiModel { get; set; } = "gpt-4.1";

    public string OpenAiCompatibleModel { get; set; } = "llama3.1";

    /// <summary>Base URL for OpenAI-compatible local servers (Ollama, LM Studio).</summary>
    public string OpenAiCompatibleBaseUrl { get; set; } = "http://127.0.0.1:11434/v1";

    public string OpenAiBaseUrl { get; set; } = "https://api.openai.com/v1";

    public string ClaudeBaseUrl { get; set; } = "https://api.anthropic.com";

    public string ActiveModelId => Provider switch
    {
        LlmProviderKind.Claude => ClaudeModel,
        LlmProviderKind.OpenAi => OpenAiModel,
        LlmProviderKind.OpenAiCompatible => OpenAiCompatibleModel,
        _ => ClaudeModel,
    };
}
