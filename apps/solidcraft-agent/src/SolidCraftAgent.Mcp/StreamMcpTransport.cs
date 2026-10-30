namespace SolidCraftAgent.Mcp;

/// <summary>
/// In-memory / injected stream transport for unit tests.
/// </summary>
public sealed class StreamMcpTransport : IMcpTransport
{
    public StreamMcpTransport(Stream input, Stream output)
    {
        Input = input;
        Output = output;
    }

    public Stream Input { get; }

    public Stream Output { get; }

    public Task StartAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;

    public ValueTask DisposeAsync() => ValueTask.CompletedTask;
}
