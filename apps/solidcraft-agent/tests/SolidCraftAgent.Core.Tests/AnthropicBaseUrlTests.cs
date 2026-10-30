using SolidCraftAgent.Llm.Providers;

namespace SolidCraftAgent.Core.Tests;

public class AnthropicBaseUrlTests
{
    [Theory]
    [InlineData("https://api.anthropic.com/v1", "https://api.anthropic.com/v1")]
    [InlineData("https://api.anthropic.com/v1/", "https://api.anthropic.com/v1")]
    [InlineData("https://api.anthropic.com", "https://api.anthropic.com/v1")]
    [InlineData("http://127.0.0.1:1234", "http://127.0.0.1:1234/v1")]
    public void NormalizeBaseUrl_MatchesSolidCraftAddAgent(string input, string expected)
    {
        Assert.Equal(expected, ClaudeChatProvider.NormalizeBaseUrl(input));
    }

    [Fact]
    public void MessagesUrl_AppendsMessagesUnderV1()
    {
        var provider = new ClaudeChatProvider(
            new HttpClient(),
            new SolidCraftAgent.Secrets.InMemorySecretStore(),
            "qwen3:14b",
            "https://api.anthropic.com/v1");
        Assert.Equal("https://api.anthropic.com/v1/messages", provider.MessagesUrl);
    }
}
