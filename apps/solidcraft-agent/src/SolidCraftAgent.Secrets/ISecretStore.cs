namespace SolidCraftAgent.Secrets;

/// <summary>
/// Abstraction over secret storage. On Windows the default implementation uses
/// Credential Manager. Unit tests and non-Windows hosts use <see cref="InMemorySecretStore"/>.
/// </summary>
public interface ISecretStore
{
    Task SetAsync(string key, string value, CancellationToken cancellationToken = default);

    Task<string?> GetAsync(string key, CancellationToken cancellationToken = default);

    Task DeleteAsync(string key, CancellationToken cancellationToken = default);
}
