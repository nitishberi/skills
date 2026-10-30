using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using System.Text;

namespace SolidCraftAgent.Secrets;

/// <summary>
/// Stores secrets in Windows Credential Manager (GENERIC credentials).
/// On non-Windows platforms construction throws; use <see cref="SecretStoreFactory"/> instead.
/// </summary>
[SupportedOSPlatform("windows")]
public sealed class WindowsCredentialSecretStore : ISecretStore
{
    private const string TargetPrefix = "SolidCraftAgent/";

    public Task SetAsync(string key, string value, CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);
        ArgumentNullException.ThrowIfNull(value);
        EnsureWindows();

        var target = TargetPrefix + key;
        var blob = Encoding.UTF8.GetBytes(value);
        var credential = new Native.Credential
        {
            Type = Native.CredentialType.Generic,
            TargetName = target,
            CredentialBlobSize = (uint)blob.Length,
            CredentialBlob = Marshal.AllocHGlobal(blob.Length),
            Persist = Native.CredentialPersist.LocalMachine,
            UserName = Environment.UserName,
            AttributeCount = 0,
            Attributes = IntPtr.Zero,
            Comment = "SolidCraft Agent secret",
        };

        try
        {
            Marshal.Copy(blob, 0, credential.CredentialBlob, blob.Length);
            if (!Native.CredWrite(ref credential, 0))
            {
                throw new InvalidOperationException(
                    $"CredWrite failed for '{key}' (Win32 {Marshal.GetLastWin32Error()}).");
            }
        }
        finally
        {
            if (credential.CredentialBlob != IntPtr.Zero)
            {
                Marshal.FreeHGlobal(credential.CredentialBlob);
            }
        }

        return Task.CompletedTask;
    }

    public Task<string?> GetAsync(string key, CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);
        EnsureWindows();

        var target = TargetPrefix + key;
        if (!Native.CredRead(target, Native.CredentialType.Generic, 0, out var credPtr))
        {
            var error = Marshal.GetLastWin32Error();
            if (error == Native.ErrorNotFound)
            {
                return Task.FromResult<string?>(null);
            }

            throw new InvalidOperationException($"CredRead failed for '{key}' (Win32 {error}).");
        }

        try
        {
            var credential = Marshal.PtrToStructure<Native.Credential>(credPtr);
            if (credential.CredentialBlob == IntPtr.Zero || credential.CredentialBlobSize == 0)
            {
                return Task.FromResult<string?>(string.Empty);
            }

            var bytes = new byte[credential.CredentialBlobSize];
            Marshal.Copy(credential.CredentialBlob, bytes, 0, bytes.Length);
            return Task.FromResult<string?>(Encoding.UTF8.GetString(bytes));
        }
        finally
        {
            Native.CredFree(credPtr);
        }
    }

    public Task DeleteAsync(string key, CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);
        EnsureWindows();

        var target = TargetPrefix + key;
        if (!Native.CredDelete(target, Native.CredentialType.Generic, 0))
        {
            var error = Marshal.GetLastWin32Error();
            if (error != Native.ErrorNotFound)
            {
                throw new InvalidOperationException($"CredDelete failed for '{key}' (Win32 {error}).");
            }
        }

        return Task.CompletedTask;
    }

    private static void EnsureWindows()
    {
        if (!OperatingSystem.IsWindows())
        {
            throw new PlatformNotSupportedException(
                "WindowsCredentialSecretStore requires Windows. Use InMemorySecretStore or FileSecretStore on other hosts.");
        }
    }

    private static class Native
    {
        public const int ErrorNotFound = 1168;

        public enum CredentialType : uint
        {
            Generic = 1,
        }

        public enum CredentialPersist : uint
        {
            Session = 1,
            LocalMachine = 2,
            Enterprise = 3,
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct Credential
        {
            public uint Flags;
            public CredentialType Type;
            public string TargetName;
            public string? Comment;
            public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
            public uint CredentialBlobSize;
            public IntPtr CredentialBlob;
            public CredentialPersist Persist;
            public uint AttributeCount;
            public IntPtr Attributes;
            public string? TargetAlias;
            public string? UserName;
        }

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool CredWrite(ref Credential credential, uint flags);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool CredRead(string target, CredentialType type, int reservedFlag, out IntPtr credentialPtr);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool CredDelete(string target, CredentialType type, int reservedFlag);

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern void CredFree(IntPtr credential);
    }
}
