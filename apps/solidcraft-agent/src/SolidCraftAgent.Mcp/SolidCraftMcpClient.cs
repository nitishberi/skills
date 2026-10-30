using System.Collections.Concurrent;
using System.Text.Json;
using System.Text.Json.Nodes;
using SolidCraftAgent.Mcp.JsonRpc;
using SolidCraftAgent.Mcp.Tools;

namespace SolidCraftAgent.Mcp;

public sealed class SolidCraftMcpClient : IAsyncDisposable
{
    private readonly IMcpTransport _transport;
    private readonly SemaphoreSlim _writeLock = new(1, 1);
    private readonly ConcurrentDictionary<string, TaskCompletionSource<JsonRpcResponse>> _pending = new();
    private CancellationTokenSource? _readCts;
    private Task? _readLoop;
    private int _nextId = 1;
    private bool _initialized;

    public SolidCraftMcpClient(IMcpTransport transport)
    {
        _transport = transport;
    }

    public IReadOnlyList<McpToolDescriptor> Tools { get; private set; } = [];

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        await _transport.StartAsync(cancellationToken).ConfigureAwait(false);
        _readCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        _readLoop = Task.Run(() => ReadLoopAsync(_readCts.Token), CancellationToken.None);

        var result = await SendRequestAsync(
            "initialize",
            new JsonObject
            {
                ["protocolVersion"] = "2024-11-05",
                ["capabilities"] = new JsonObject(),
                ["clientInfo"] = new JsonObject
                {
                    ["name"] = "SolidCraftAgent",
                    ["version"] = "1.0.0",
                },
            },
            cancellationToken).ConfigureAwait(false);

        if (result.Error is not null)
        {
            throw new McpKernelException($"MCP initialize failed: {result.Error.Message}", raw: result.Error.Data?.ToJsonString());
        }

        await SendNotificationAsync("notifications/initialized", new JsonObject(), cancellationToken).ConfigureAwait(false);
        await RefreshToolsAsync(cancellationToken).ConfigureAwait(false);
        _initialized = true;
    }

    public async Task RefreshToolsAsync(CancellationToken cancellationToken = default)
    {
        var response = await SendRequestAsync("tools/list", new JsonObject(), cancellationToken).ConfigureAwait(false);
        if (response.Error is not null)
        {
            throw new McpKernelException($"tools/list failed: {response.Error.Message}", raw: response.Error.Data?.ToJsonString());
        }

        var tools = new List<McpToolDescriptor>();
        var toolsNode = response.Result?["tools"] as JsonArray;
        if (toolsNode is not null)
        {
            foreach (var item in toolsNode)
            {
                if (item is not JsonObject obj)
                {
                    continue;
                }

                var name = obj["name"]?.GetValue<string>() ?? string.Empty;
                var description = obj["description"]?.GetValue<string>();
                var schema = obj["inputSchema"]?.DeepClone();
                tools.Add(new McpToolDescriptor(name, description, schema));
            }
        }

        Tools = tools;
    }

    public async Task<McpToolCallResult> CallToolAsync(
        string toolName,
        JsonNode? arguments,
        CancellationToken cancellationToken = default)
    {
        EnsureInitialized();
        ArgumentException.ThrowIfNullOrWhiteSpace(toolName);

        var response = await SendRequestAsync(
            "tools/call",
            new JsonObject
            {
                ["name"] = toolName,
                ["arguments"] = arguments?.DeepClone() ?? new JsonObject(),
            },
            cancellationToken).ConfigureAwait(false);

        if (response.Error is not null)
        {
            var message = $"SolidCraft tool '{toolName}' failed: {response.Error.Message}";
            if (string.Equals(toolName, SolidCraftToolNames.Batch, StringComparison.Ordinal))
            {
                throw new McpBatchException(message, response.Error.Data?.ToJsonString());
            }

            throw new McpKernelException(message, toolName, response.Error.Data?.ToJsonString());
        }

        return ParseToolResult(toolName, response.Result);
    }

    /// <summary>
    /// Runs a SolidCraft <c>batch</c> call. Failure rolls back the whole batch (server semantics)
    /// and is surfaced as <see cref="McpBatchException"/>.
    /// </summary>
    public Task<McpToolCallResult> CallBatchAsync(JsonNode batchArguments, CancellationToken cancellationToken = default) =>
        CallToolAsync(SolidCraftToolNames.Batch, batchArguments, cancellationToken);

    public async Task<McpToolCallResult> NewDesignAsync(string? name = null, CancellationToken cancellationToken = default)
    {
        var args = new JsonObject();
        if (!string.IsNullOrWhiteSpace(name))
        {
            args["name"] = name;
        }

        return await CallToolAsync(SolidCraftToolNames.NewDesign, args, cancellationToken).ConfigureAwait(false);
    }

    public Task<McpToolCallResult> SetUnitsMmAsync(CancellationToken cancellationToken = default) =>
        CallToolAsync(SolidCraftToolNames.DocumentUnits, new JsonObject { ["units"] = "mm" }, cancellationToken);

    public Task<McpToolCallResult> SaveAsync(string path, CancellationToken cancellationToken = default) =>
        CallToolAsync(SolidCraftToolNames.Save, new JsonObject { ["path"] = path }, cancellationToken);

    private static McpToolCallResult ParseToolResult(string toolName, JsonNode? result)
    {
        if (result is null)
        {
            return new McpToolCallResult(false, string.Empty);
        }

        var isError = result["isError"]?.GetValue<bool>() == true;
        var contentNode = result["content"];
        var text = contentNode switch
        {
            JsonArray array => string.Join(
                Environment.NewLine,
                array.OfType<JsonObject>()
                    .Select(o => o["text"]?.GetValue<string>() ?? o.ToJsonString())),
            JsonValue value when value.TryGetValue<string>(out var s) => s,
            _ => result.ToJsonString(),
        };

        if (isError)
        {
            if (string.Equals(toolName, SolidCraftToolNames.Batch, StringComparison.Ordinal))
            {
                throw new McpBatchException($"Batch failed: {text}", result.ToJsonString());
            }

            throw new McpKernelException($"Tool '{toolName}' returned an error: {text}", toolName, result.ToJsonString());
        }

        return new McpToolCallResult(false, text, result);
    }

    private async Task ReadLoopAsync(CancellationToken cancellationToken)
    {
        try
        {
            while (!cancellationToken.IsCancellationRequested)
            {
                var json = await McpFraming.ReadMessageAsync(_transport.Output, cancellationToken).ConfigureAwait(false);
                using var doc = JsonDocument.Parse(json);
                if (!doc.RootElement.TryGetProperty("id", out var idEl) || idEl.ValueKind is JsonValueKind.Null or JsonValueKind.Undefined)
                {
                    // Notification from server: ignore for v1.
                    continue;
                }

                var id = idEl.ValueKind == JsonValueKind.Number
                    ? idEl.GetRawText()
                    : idEl.GetString() ?? idEl.GetRawText();

                if (_pending.TryRemove(id, out var tcs))
                {
                    var response = JsonRpcSerializer.DeserializeResponse(json);
                    tcs.TrySetResult(response);
                }
            }
        }
        catch (OperationCanceledException)
        {
            // Expected on dispose.
        }
        catch (Exception ex)
        {
            foreach (var pending in _pending)
            {
                pending.Value.TrySetException(ex);
            }

            _pending.Clear();
        }
    }

    private async Task<JsonRpcResponse> SendRequestAsync(string method, JsonNode? @params, CancellationToken cancellationToken)
    {
        var id = Interlocked.Increment(ref _nextId);
        var idText = id.ToString();
        var request = new JsonRpcRequest
        {
            Id = JsonValue.Create(id),
            Method = method,
            Params = @params,
        };

        var tcs = new TaskCompletionSource<JsonRpcResponse>(TaskCreationOptions.RunContinuationsAsynchronously);
        if (!_pending.TryAdd(idText, tcs))
        {
            throw new InvalidOperationException($"Duplicate MCP request id {idText}.");
        }

        await using var registration = cancellationToken.Register(() =>
        {
            if (_pending.TryRemove(idText, out var pending))
            {
                pending.TrySetCanceled(cancellationToken);
            }
        });

        var payload = JsonRpcSerializer.SerializeRequest(request);
        var framed = McpFraming.EncodeMessage(payload);
        await _writeLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            await _transport.Input.WriteAsync(framed, cancellationToken).ConfigureAwait(false);
            await _transport.Input.FlushAsync(cancellationToken).ConfigureAwait(false);
        }
        finally
        {
            _writeLock.Release();
        }

        return await tcs.Task.ConfigureAwait(false);
    }

    private async Task SendNotificationAsync(string method, JsonNode? @params, CancellationToken cancellationToken)
    {
        var notification = new JsonRpcNotification
        {
            Method = method,
            Params = @params,
        };
        var payload = JsonRpcSerializer.SerializeNotification(notification);
        var framed = McpFraming.EncodeMessage(payload);
        await _writeLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            await _transport.Input.WriteAsync(framed, cancellationToken).ConfigureAwait(false);
            await _transport.Input.FlushAsync(cancellationToken).ConfigureAwait(false);
        }
        finally
        {
            _writeLock.Release();
        }
    }

    private void EnsureInitialized()
    {
        if (!_initialized)
        {
            throw new InvalidOperationException("Call InitializeAsync before using the SolidCraft MCP client.");
        }
    }

    private int _disposed;

    public async ValueTask DisposeAsync()
    {
        if (Interlocked.Exchange(ref _disposed, 1) != 0)
        {
            return;
        }

        if (_readCts is not null)
        {
            await _readCts.CancelAsync().ConfigureAwait(false);
        }

        if (_readLoop is not null)
        {
            try
            {
                await _readLoop.ConfigureAwait(false);
            }
            catch
            {
                // Ignore shutdown races.
            }
        }

        _readCts?.Dispose();
        _writeLock.Dispose();
        await _transport.DisposeAsync().ConfigureAwait(false);
    }
}
