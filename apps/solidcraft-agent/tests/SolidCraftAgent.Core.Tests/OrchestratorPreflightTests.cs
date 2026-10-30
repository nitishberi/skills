using System.Text.Json.Nodes;
using SolidCraftAgent.Core.Agent;
using SolidCraftAgent.Core.Config;
using SolidCraftAgent.Core.Lessons;
using SolidCraftAgent.Core.Seed;
using SolidCraftAgent.Llm;
using SolidCraftAgent.Llm.Abstractions;
using SolidCraftAgent.Mcp;
using SolidCraftAgent.Mcp.JsonRpc;
using SolidCraftAgent.Mcp.Tools;
using SolidCraftAgent.Secrets;

namespace SolidCraftAgent.Core.Tests;

public class OrchestratorPreflightTests
{
    [Fact]
    public async Task Preflight_ReportsOk_WithSeededLessons()
    {
        var dir = Path.Combine(Path.GetTempPath(), "solidcraft-orch-" + Guid.NewGuid().ToString("N"));
        var lessons = new LessonStore(Path.Combine(dir, "lessons"));
        var settings = new AppSettings
        {
            DataDirectory = dir,
            PermanentModelsFolder = Path.Combine(dir, "models"),
        };
        var orchestrator = new AgentOrchestrator(
            settings,
            lessons,
            new SystemPromptBuilder(lessons),
            new FixedChatProviderFactory(new ScriptedChatProvider([])),
            _ => throw new InvalidOperationException("MCP should not start during preflight."));

        var findings = await orchestrator.RunPreflightChecksAsync();
        Assert.Contains(findings, f => f.StartsWith("Preflight OK", StringComparison.Ordinal));
    }

    [Fact]
    public async Task Correction_CreatesPendingLesson_WithoutToolCalls()
    {
        var dir = Path.Combine(Path.GetTempPath(), "solidcraft-corr-" + Guid.NewGuid().ToString("N"));
        var lessons = new LessonStore(Path.Combine(dir, "lessons"));
        await lessons.EnsureSeededAsync();
        var settings = new AppSettings { DataDirectory = dir, PermanentModelsFolder = Path.Combine(dir, "models") };

        var fakeProvider = new ScriptedChatProvider(
        [
            new ChatResponse(
                "Diagnosed reverse thickness; rib should be 1.00 and ends .500. Rebuilt.",
                Array.Empty<ToolCall>(),
                "end"),
        ]);

        // Orchestrator disposes the MCP client at the end of the turn; do not double-dispose here.
        var mcp = await CreateInitializedFakeMcpAsync();
        var orchestrator = new AgentOrchestrator(
            settings,
            lessons,
            new SystemPromptBuilder(lessons),
            new FixedChatProviderFactory(fakeProvider),
            _ => Task.FromResult(mcp));

        var reply = await orchestrator.RunUserTurnAsync(
            "The features are extruded in reverse. The rib should be 1 and the ends 1/2 thick.");

        Assert.Contains("Diagnosed", reply);
        var pending = await lessons.ListAsync(LessonStatus.Pending);
        Assert.NotEmpty(pending);
        Assert.Contains(pending, p => p.Title.Contains("Correction", StringComparison.Ordinal));
    }

    private static async Task<SolidCraftMcpClient> CreateInitializedFakeMcpAsync()
    {
        var duplex = new DuplexPipe();
        var server = Task.Run(async () =>
        {
            while (true)
            {
                string json;
                try
                {
                    json = await McpFraming.ReadMessageAsync(duplex.ServerReadable);
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
                        ["capabilities"] = new JsonObject(),
                        ["serverInfo"] = new JsonObject { ["name"] = "fake" },
                    },
                    "tools/list" => new JsonObject
                    {
                        ["tools"] = new JsonArray
                        {
                            new JsonObject
                            {
                                ["name"] = SolidCraftToolNames.NewDesign,
                                ["description"] = "new",
                                ["inputSchema"] = new JsonObject { ["type"] = "object" },
                            },
                        },
                    },
                    _ => new JsonObject(),
                };
                var response = new JsonObject { ["jsonrpc"] = "2.0", ["id"] = id, ["result"] = result };
                var framed = McpFraming.EncodeMessage(response.ToJsonString());
                await duplex.ServerWritable.WriteAsync(framed);
                await duplex.ServerWritable.FlushAsync();
            }
        });

        var transport = new StreamMcpTransport(duplex.ClientWritable, duplex.ClientReadable);
        var client = new SolidCraftMcpClient(transport);
        await client.InitializeAsync();
        _ = server;
        return client;
    }

    private sealed class ScriptedChatProvider : IChatProvider
    {
        private readonly Queue<ChatResponse> _responses;

        public ScriptedChatProvider(IEnumerable<ChatResponse> responses) =>
            _responses = new Queue<ChatResponse>(responses);

        public LlmProviderKind Kind => LlmProviderKind.Claude;

        public string ModelId => "scripted";

        public Task<ChatResponse> CompleteAsync(ChatRequest request, CancellationToken cancellationToken = default) =>
            Task.FromResult(_responses.Dequeue());
    }

    private sealed class FixedChatProviderFactory : IChatProviderFactory
    {
        private readonly IChatProvider _provider;

        public FixedChatProviderFactory(IChatProvider provider) => _provider = provider;

        public IChatProvider Create(LlmSettings settings) => _provider;
    }

    private sealed class DuplexPipe
    {
        private readonly BlockingMemoryStream _c2s = new();
        private readonly BlockingMemoryStream _s2c = new();

        public Stream ClientWritable => _c2s;
        public Stream ServerReadable => _c2s;
        public Stream ServerWritable => _s2c;
        public Stream ClientReadable => _s2c;
    }

    private sealed class BlockingMemoryStream : Stream
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

        public override ValueTask WriteAsync(ReadOnlyMemory<byte> buffer, CancellationToken cancellationToken = default)
        {
            Write(buffer.ToArray(), 0, buffer.Length);
            return ValueTask.CompletedTask;
        }

        public override int Read(byte[] buffer, int offset, int count) =>
            ReadAsync(buffer, offset, count).GetAwaiter().GetResult();

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
    }
}
