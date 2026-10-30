using System.Text;
using SolidCraftAgent.Mcp.JsonRpc;

namespace SolidCraftAgent.Mcp.Tests;

public class McpFramingTests
{
    [Fact]
    public void EncodeMessage_PrefixesContentLengthHeader()
    {
        var json = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\"}";
        var framed = McpFraming.EncodeMessage(json);
        var text = Encoding.UTF8.GetString(framed);
        Assert.StartsWith($"Content-Length: {Encoding.UTF8.GetByteCount(json)}\r\n\r\n", text);
        Assert.EndsWith(json, text);
    }

    [Fact]
    public void DecodeMessage_RoundTripsBody()
    {
        var json = "{\"jsonrpc\":\"2.0\",\"result\":{\"ok\":true}}";
        var framed = McpFraming.EncodeMessage(json);
        var decoded = McpFraming.DecodeMessage(framed);
        Assert.Equal(json, decoded);
    }

    [Fact]
    public async Task ReadMessageAsync_ReadsFramedStream()
    {
        var json = "{\"jsonrpc\":\"2.0\",\"id\":7,\"result\":{}}";
        var framed = McpFraming.EncodeMessage(json);
        await using var stream = new MemoryStream(framed);
        var read = await McpFraming.ReadMessageAsync(stream);
        Assert.Equal(json, read);
    }

    [Fact]
    public void JsonRpcSerializer_RoundTripsRequest()
    {
        var request = new JsonRpcRequest
        {
            Id = System.Text.Json.Nodes.JsonValue.Create(3),
            Method = "tools/call",
            Params = new System.Text.Json.Nodes.JsonObject { ["name"] = "batch" },
        };
        var json = JsonRpcSerializer.SerializeRequest(request);
        Assert.Contains("\"method\":\"tools/call\"", json);
        Assert.Contains("\"jsonrpc\":\"2.0\"", json);
    }
}
