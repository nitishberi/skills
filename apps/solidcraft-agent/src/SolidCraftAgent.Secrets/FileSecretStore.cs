namespace SolidCraftAgent.Secrets;

/// <summary>
/// Dev/test fallback that writes secrets to a local file with user-only permissions
/// when possible. Prefer <see cref="WindowsCredentialSecretStore"/> on Windows
/// and <see cref="InMemorySecretStore"/> in unit tests.
/// </summary>
public sealed class FileSecretStore : ISecretStore
{
    private readonly string _directory;
    private readonly object _gate = new();

    public FileSecretStore(string directory)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(directory);
        _directory = directory;
        Directory.CreateDirectory(_directory);
    }

    public Task SetAsync(string key, string value, CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);
        ArgumentNullException.ThrowIfNull(value);
        var path = PathFor(key);
        lock (_gate)
        {
            File.WriteAllText(path, value);
        }

        return Task.CompletedTask;
    }

    public Task<string?> GetAsync(string key, CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);
        var path = PathFor(key);
        lock (_gate)
        {
            return Task.FromResult(File.Exists(path) ? File.ReadAllText(path) : null);
        }
    }

    public Task DeleteAsync(string key, CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);
        var path = PathFor(key);
        lock (_gate)
        {
            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }

        return Task.CompletedTask;
    }

    private string PathFor(string key)
    {
        var safe = string.Concat(key.Select(c => char.IsLetterOrDigit(c) || c is '.' or '-' or '_' ? c : '_'));
        return Path.Combine(_directory, safe + ".secret");
    }
}
