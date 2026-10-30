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
        return settings.Provider switch
        {
            LlmProviderKind.Claude => new ClaudeChatProvider(
                _http,
                _secrets,
                settings.ClaudeModel,
                settings.ClaudeBaseUrl),
            LlmProviderKind.OpenAi => new OpenAiCompatibleChatProvider(
                _http,
                _secrets,
                LlmProviderKind.OpenAi,
                settings.OpenAiModel,
                settings.OpenAiBaseUrl,
                SecretKeys.OpenAiApiKey,
                requireApiKey: true),
            LlmProviderKind.OpenAiCompatible => new OpenAiCompatibleChatProvider(
                _http,
                _secrets,
                LlmProviderKind.OpenAiCompatible,
                settings.OpenAiCompatibleModel,
                settings.OpenAiCompatibleBaseUrl,
                SecretKeys.OpenAiCompatibleApiKey,
                requireApiKey: false),
            _ => throw new ArgumentOutOfRangeException(nameof(settings), settings.Provider, "Unknown LLM provider."),
        };
    }
}
