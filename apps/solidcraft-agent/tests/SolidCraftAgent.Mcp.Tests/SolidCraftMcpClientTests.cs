using System.Text;
using System.Text.Json.Nodes;
using SolidCraftAgent.Mcp;
using SolidCraftAgent.Mcp.JsonRpc;
using SolidCraftAgent.Mcp.Tools;

namespace SolidCraftAgent.Mcp.Tests;

public class SolidCraftMcpClientTests
{
    [Fact]
    public async Task Initialize_ListsTools_AndCallsBatch()
    {
        await using var clientToServer = new ProducerConsumerStream();
        await using var serverToClient = new ProducerConsumerStream();

        var serverTask = Task.Run(async () =>
        {
            while (true)
            {
                string json;
                try
                {
                    json = await McpFraming.ReadMessageAsync(clientToServer.Readable);
                }
                catch (EndOfStreamException)
                {
                    break;
                }

                var node = JsonNode.Parse(json)!.AsObject();
                if (!node.ContainsKey("id"))
                {
                    continue;
                }

                var id = node["id"]!.DeepClone();
                var method = node["method"]!.GetValue<string>();
                JsonNode result = method switch
                {
                    "initialize" => new JsonObject
                    {
                        ["protocolVersion"] = "2024-11-05",
                        ["serverInfo"] = new JsonObject { ["name"] = "fake-solidcraft" },
                        ["capabilities"] = new JsonObject(),
                    },
                    "tools/list" => new JsonObject
                    {
                        ["tools"] = new JsonArray
                        {
                            new JsonObject
                            {
                                ["name"] = SolidCraftToolNames.Batch,
                                ["description"] = "all-or-nothing",
                                ["inputSchema"] = new JsonObject { ["type"] = "object" },
                            },
                            new JsonObject
                            {
                                ["name"] = SolidCraftToolNames.NewDesign,
                                ["description"] = "new design",
                                ["inputSchema"] = new JsonObject { ["type"] = "object" },
                            },
                        },
                    },
                    "tools/call" => new JsonObject
                    {
                        ["content"] = new JsonArray
                        {
                            new JsonObject { ["type"] = "text", ["text"] = "batch ok" },
                        },
                        ["isError"] = false,
                    },
                    _ => new JsonObject(),
                };

                var response = new JsonObject
                {
                    ["jsonrpc"] = "2.0",
                    ["id"] = id,
                    ["result"] = result,
                };
                var framed = McpFraming.EncodeMessage(response.ToJsonString());
                await serverToClient.Writable.WriteAsync(framed);
                await serverToClient.Writable.FlushAsync();
            }
        });

        var transport = new StreamMcpTransport(clientToServer.Writable, serverToClient.Readable);
        await using var client = new SolidCraftMcpClient(transport);
        await client.InitializeAsync();

        Assert.Contains(client.Tools, t => t.Name == SolidCraftToolNames.Batch);
        var batch = await client.CallBatchAsync(new JsonObject { ["steps"] = new JsonArray() });
        Assert.Contains("batch ok", batch.Content);

        clientToServer.Writable.Complete();
        await serverTask;
    }

    [Fact]
    public async Task CallTool_SurfacesBatchErrors()
    {
        await using var clientToServer = new ProducerConsumerStream();
        await using var serverToClient = new ProducerConsumerStream();

        _ = Task.Run(async () =>
        {
            while (true)
            {
                string json;
                try
                {
                    json = await McpFraming.ReadMessageAsync(clientToServer.Readable);
                }
                catch (EndOfStreamException)
                {
                    break;
                }

                var node = JsonNode.Parse(json)!.AsObject();
                if (!node.ContainsKey("id"))
                {
                    continue;
                }

                var id = node["id"]!.DeepClone();
                var method = node["method"]!.GetValue<string>();
                JsonNode? result = null;
                JsonNode? error = null;
                if (method == "initialize")
                {
                    result = new JsonObject { ["protocolVersion"] = "2024-11-05", ["capabilities"] = new JsonObject(), ["serverInfo"] = new JsonObject { ["name"] = "x" } };
                }
                else if (method == "tools/list")
                {
                    result = new JsonObject { ["tools"] = new JsonArray() };
                }
                else if (method == "tools/call")
                {
                    result = new JsonObject
                    {
                        ["isError"] = true,
                        ["content"] = new JsonArray
                        {
                            new JsonObject { ["type"] = "text", ["text"] = "fillet blend larger than neighbouring faces" },
                        },
                    };
                }

                var response = new JsonObject { ["jsonrpc"] = "2.0", ["id"] = id };
                if (result is not null)
                {
                    response["result"] = result;
                }

                if (error is not null)
                {
                    response["error"] = error;
                }

                var framed = McpFraming.EncodeMessage(response.ToJsonString());
                await serverToClient.Writable.WriteAsync(framed);
                await serverToClient.Writable.FlushAsync();
            }
        });

        var transport = new StreamMcpTransport(clientToServer.Writable, serverToClient.Readable);
        await using var client = new SolidCraftMcpClient(transport);
        await client.InitializeAsync();

        var ex = await Assert.ThrowsAsync<McpBatchException>(() =>
            client.CallBatchAsync(new JsonObject()));
        Assert.Contains("fillet", ex.Message, StringComparison.OrdinalIgnoreCase);
        clientToServer.Writable.Complete();
    }

    /// <summary>Simple duplex stream pair for fake MCP servers in tests.</summary>
    private sealed class ProducerConsumerStream : IAsyncDisposable
    {
        private readonly BlockingStream _a = new();
        private readonly BlockingStream _b = new();

        // Client writes to Writable; server reads Readable of the same logical direction.
        public Stream Writable => _a;
        public Stream Readable => _a;

        public ValueTask DisposeAsync()
        {
            _a.Dispose();
            _b.Dispose();
            return ValueTask.CompletedTask;
        }
    }

    private sealed class BlockingStream : Stream
    {
        private readonly MemoryStream _buffer = new();
        private readonly SemaphoreSlim _data = new(0);
        private readonly object _gate = new();
        private bool _completed;
        private long _readPos;

        public override bool CanRead => true;
        public override bool CanSeek => false;
        public override bool CanWrite => true;
        public override long Length => throw new NotSupportedException();
        public override long Position { get => throw new NotSupportedException(); set => throw new NotSupportedException(); }
        public override void Flush() { }
        public override Task FlushAsync(CancellationToken cancellationToken) => Task.CompletedTask;
        public override long Seek(long offset, SeekOrigin origin) => throw new NotSupportedException();
        public override void SetLength(long value) => throw new NotSupportedException();

        public void Complete()
        {
            lock (_gate)
            {
                _completed = true;
            }

            _data.Release();
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            lock (_gate)
            {
                var pos = _buffer.Position;
                _buffer.Position = _buffer.Length;
                _buffer.Write(buffer, offset, count);
                _buffer.Position = pos;
            }

            _data.Release();
        }

        public override async Task WriteAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken)
        {
            Write(buffer, offset, count);
            await Task.CompletedTask;
        }

        public override ValueTask WriteAsync(ReadOnlyMemory<byte> buffer, CancellationToken cancellationToken = default)
        {
            Write(buffer.ToArray(), 0, buffer.Length);
            return ValueTask.CompletedTask;
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            return ReadAsync(buffer, offset, count).GetAwaiter().GetResult();
        }

        public override async Task<int> ReadAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken)
        {
            while (true)
            {
                lock (_gate)
                {
                    if (_readPos < _buffer.Length)
                    {
                        _buffer.Position = _readPos;
                        var n = _buffer.Read(buffer, offset, count);
                        _readPos = _buffer.Position;
                        return n;
                    }

                    if (_completed)
                    {
                        return 0;
                    }
                }

                await _data.WaitAsync(cancellationToken).ConfigureAwait(false);
            }
        }

        public override async ValueTask<int> ReadAsync(Memory<byte> buffer, CancellationToken cancellationToken = default)
        {
            var tmp = new byte[buffer.Length];
            var n = await ReadAsync(tmp, 0, tmp.Length, cancellationToken).ConfigureAwait(false);
            tmp.AsSpan(0, n).CopyTo(buffer.Span);
            return n;
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                Complete();
                _buffer.Dispose();
                _data.Dispose();
            }

            base.Dispose(disposing);
        }
    }
}
