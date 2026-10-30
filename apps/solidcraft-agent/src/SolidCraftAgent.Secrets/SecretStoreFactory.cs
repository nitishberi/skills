namespace SolidCraftAgent.Secrets;

public static class SecretStoreFactory
{
    /// <summary>
    /// Creates the best available secret store for the current OS.
    /// Windows: Credential Manager. Elsewhere: file store under <paramref name="fallbackDirectory"/>
    /// (or an in-memory store when the directory is null).
    /// </summary>
    public static ISecretStore CreateDefault(string? fallbackDirectory = null)
    {
        if (OperatingSystem.IsWindows())
        {
            return new WindowsCredentialSecretStore();
        }

        if (!string.IsNullOrWhiteSpace(fallbackDirectory))
        {
            return new FileSecretStore(fallbackDirectory);
        }

        return new InMemorySecretStore();
    }
}
