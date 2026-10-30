namespace SolidCraftAgent.Llm.Abstractions;

public interface IChatProvider
{
    LlmProviderKind Kind { get; }

    string ModelId { get; }

    Task<ChatResponse> CompleteAsync(ChatRequest request, CancellationToken cancellationToken = default);
}
