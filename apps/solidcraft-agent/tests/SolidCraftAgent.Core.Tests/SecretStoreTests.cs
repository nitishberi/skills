using SolidCraftAgent.Secrets;

namespace SolidCraftAgent.Core.Tests;

public class SecretStoreTests
{
    [Fact]
    public async Task InMemorySecretStore_RoundTrips()
    {
        var store = new InMemorySecretStore();
        await store.SetAsync(SecretKeys.ClaudeApiKey, "secret-value");
        Assert.Equal("secret-value", await store.GetAsync(SecretKeys.ClaudeApiKey));
        await store.DeleteAsync(SecretKeys.ClaudeApiKey);
        Assert.Null(await store.GetAsync(SecretKeys.ClaudeApiKey));
    }

    [Fact]
    public async Task FileSecretStore_PersistsAcrossInstances()
    {
        var dir = Path.Combine(Path.GetTempPath(), "solidcraft-secrets-" + Guid.NewGuid().ToString("N"));
        var store = new FileSecretStore(dir);
        await store.SetAsync(SecretKeys.OpenAiApiKey, "openai-key");
        var store2 = new FileSecretStore(dir);
        Assert.Equal("openai-key", await store2.GetAsync(SecretKeys.OpenAiApiKey));
    }

    [Fact]
    public void Factory_OnNonWindows_UsesFallback()
    {
        if (OperatingSystem.IsWindows())
        {
            var store = SecretStoreFactory.CreateDefault();
            Assert.IsType<WindowsCredentialSecretStore>(store);
            return;
        }

        var memory = SecretStoreFactory.CreateDefault(fallbackDirectory: null);
        Assert.IsType<InMemorySecretStore>(memory);
        var dir = Path.Combine(Path.GetTempPath(), "solidcraft-secfactory-" + Guid.NewGuid().ToString("N"));
        var file = SecretStoreFactory.CreateDefault(dir);
        Assert.IsType<FileSecretStore>(file);
    }
}
