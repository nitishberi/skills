using SolidCraftAgent.Llm.Abstractions;

namespace SolidCraftAgent.Llm;

public interface IChatProviderFactory
{
    IChatProvider Create(LlmSettings settings);
}
