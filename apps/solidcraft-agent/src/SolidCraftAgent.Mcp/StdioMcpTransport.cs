using System.Diagnostics;

namespace SolidCraftAgent.Mcp;

/// <summary>
/// Launches a SolidCraft MCP server process and exposes its stdio streams.
/// </summary>
public sealed class StdioMcpTransport : IMcpTransport
{
    private readonly string _command;
    private readonly string _arguments;
    private readonly string? _workingDirectory;
    private Process? _process;

    public StdioMcpTransport(string command, string arguments = "", string? workingDirectory = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(command);
        _command = command;
        _arguments = arguments ?? string.Empty;
        _workingDirectory = workingDirectory;
    }

    public Stream Input => _process?.StandardInput.BaseStream
        ?? throw new InvalidOperationException("Transport has not been started.");

    public Stream Output => _process?.StandardOutput.BaseStream
        ?? throw new InvalidOperationException("Transport has not been started.");

    public int? ProcessId => _process?.Id;

    public Task StartAsync(CancellationToken cancellationToken = default)
    {
        if (_process is not null)
        {
            return Task.CompletedTask;
        }

        var startInfo = new ProcessStartInfo
        {
            FileName = _command,
            Arguments = _arguments,
            WorkingDirectory = _workingDirectory ?? Environment.CurrentDirectory,
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        };

        _process = Process.Start(startInfo)
            ?? throw new InvalidOperationException($"Failed to start MCP process '{_command}'.");

        _ = Task.Run(async () =>
        {
            try
            {
                var err = await _process.StandardError.ReadToEndAsync(cancellationToken).ConfigureAwait(false);
                if (!string.IsNullOrWhiteSpace(err))
                {
                    Debug.WriteLine($"[SolidCraft MCP stderr] {err}");
                }
            }
            catch
            {
                // Process may already have exited.
            }
        }, CancellationToken.None);

        return Task.CompletedTask;
    }

    public async ValueTask DisposeAsync()
    {
        if (_process is null)
        {
            return;
        }

        try
        {
            if (!_process.HasExited)
            {
                _process.Kill(entireProcessTree: true);
                await _process.WaitForExitAsync().ConfigureAwait(false);
            }
        }
        catch
        {
            // Best effort shutdown.
        }
        finally
        {
            _process.Dispose();
            _process = null;
        }
    }
}
