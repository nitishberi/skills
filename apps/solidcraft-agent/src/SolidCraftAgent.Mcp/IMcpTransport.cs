namespace SolidCraftAgent.Mcp;

public interface IMcpTransport : IAsyncDisposable
{
    Stream Input { get; }

    Stream Output { get; }

    Task StartAsync(CancellationToken cancellationToken = default);
}
