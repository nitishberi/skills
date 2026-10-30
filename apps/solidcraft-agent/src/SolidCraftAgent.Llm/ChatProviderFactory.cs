using SolidCraftAgent.Llm.Abstractions;
using SolidCraftAgent.Llm.Providers;
using SolidCraftAgent.Secrets;

namespace SolidCraftAgent.Llm;

public sealed class ChatProviderFactory : IChatProviderFactory
{
    private readonly HttpClient _http;
    private readonly ISecretStore _secrets;

    public ChatProviderFactory(HttpClient http, ISecretStore secrets)
    {
        _http = http;
        _secrets = secrets;
    }

    public IChatProvider Create(LlmSettings settings)
    {
        ArgumentNullException.ThrowIfNull(settings);
        // Mirror SolidCraft "Add agent": Anthropic-compatible and OpenAI-compatible API
        // endpoints; API key optional for local servers (kept in keychain when set).
        return settings.Provider switch
        {
            LlmProviderKind.Claude => new ClaudeChatProvider(
                _http,
                _secrets,
                settings.ClaudeModel,
                settings.ClaudeBaseUrl,
                requireApiKey: false,
                requestTimeoutSeconds: settings.RequestTimeoutSeconds),
            LlmProviderKind.OpenAi => new OpenAiCompatibleChatProvider(
                _http,
                _secrets,
                LlmProviderKind.OpenAi,
                settings.OpenAiModel,
                settings.OpenAiBaseUrl,
                SecretKeys.OpenAiApiKey,
                requireApiKey: true,
                requestTimeoutSeconds: settings.RequestTimeoutSeconds),
            LlmProviderKind.OpenAiCompatible => new OpenAiCompatibleChatProvider(
                _http,
                _secrets,
                LlmProviderKind.OpenAiCompatible,
                settings.OpenAiCompatibleModel,
                settings.OpenAiCompatibleBaseUrl,
                SecretKeys.OpenAiCompatibleApiKey,
                requireApiKey: false,
                requestTimeoutSeconds: settings.RequestTimeoutSeconds),
            _ => throw new ArgumentOutOfRangeException(nameof(settings), settings.Provider, "Unknown LLM provider."),
        };
    }
}
