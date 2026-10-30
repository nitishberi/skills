using System.Buffers;
using System.Globalization;
using System.Text;

namespace SolidCraftAgent.Mcp.JsonRpc;

/// <summary>
/// MCP stdio framing: Content-Length headers + UTF-8 JSON body (LSP-style).
/// </summary>
public static class McpFraming
{
    public static byte[] EncodeMessage(string json)
    {
        ArgumentNullException.ThrowIfNull(json);
        var body = Encoding.UTF8.GetBytes(json);
        var header = Encoding.ASCII.GetBytes($"Content-Length: {body.Length}\r\n\r\n");
        var message = new byte[header.Length + body.Length];
        Buffer.BlockCopy(header, 0, message, 0, header.Length);
        Buffer.BlockCopy(body, 0, message, header.Length, body.Length);
        return message;
    }

    public static async Task<string> ReadMessageAsync(Stream stream, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(stream);
        var headers = await ReadHeadersAsync(stream, cancellationToken).ConfigureAwait(false);
        if (!headers.TryGetValue("content-length", out var lengthText)
            || !int.TryParse(lengthText, NumberStyles.Integer, CultureInfo.InvariantCulture, out var length)
            || length < 0)
        {
            throw new InvalidOperationException("MCP message missing a valid Content-Length header.");
        }

        var buffer = ArrayPool<byte>.Shared.Rent(length);
        try
        {
            var read = 0;
            while (read < length)
            {
                var n = await stream.ReadAsync(buffer.AsMemory(read, length - read), cancellationToken).ConfigureAwait(false);
                if (n == 0)
                {
                    throw new EndOfStreamException("MCP stream ended before the full message body arrived.");
                }

                read += n;
            }

            return Encoding.UTF8.GetString(buffer, 0, length);
        }
        finally
        {
            ArrayPool<byte>.Shared.Return(buffer);
        }
    }

    /// <summary>
    /// Parses a complete framed buffer (headers + body) for unit tests without a live stream.
    /// </summary>
    public static string DecodeMessage(ReadOnlySpan<byte> framed)
    {
        var text = Encoding.UTF8.GetString(framed);
        var separator = text.IndexOf("\r\n\r\n", StringComparison.Ordinal);
        if (separator < 0)
        {
            throw new InvalidOperationException("Framed MCP message is missing the header/body separator.");
        }

        var headerBlock = text[..separator];
        var body = text[(separator + 4)..];
        var headers = ParseHeaderBlock(headerBlock);
        if (!headers.TryGetValue("content-length", out var lengthText)
            || !int.TryParse(lengthText, NumberStyles.Integer, CultureInfo.InvariantCulture, out var length))
        {
            throw new InvalidOperationException("Framed MCP message missing Content-Length.");
        }

        var bodyBytes = Encoding.UTF8.GetByteCount(body);
        if (bodyBytes != length)
        {
            // Allow exact UTF-8 body as encoded; decode from original bytes for accuracy.
            var bodyStart = Encoding.UTF8.GetByteCount(text[..(separator + 4)]);
            return Encoding.UTF8.GetString(framed.Slice(bodyStart, length));
        }

        return body;
    }

    private static async Task<Dictionary<string, string>> ReadHeadersAsync(Stream stream, CancellationToken cancellationToken)
    {
        var buffer = new MemoryStream();
        var window = new byte[1];
        while (true)
        {
            var n = await stream.ReadAsync(window.AsMemory(0, 1), cancellationToken).ConfigureAwait(false);
            if (n == 0)
            {
                throw new EndOfStreamException("MCP stream ended while reading headers.");
            }

            buffer.WriteByte(window[0]);
            if (buffer.Length >= 4)
            {
                var arr = buffer.ToArray();
                if (arr[^4] == (byte)'\r' && arr[^3] == (byte)'\n' && arr[^2] == (byte)'\r' && arr[^1] == (byte)'\n')
                {
                    var headerText = Encoding.ASCII.GetString(arr, 0, arr.Length - 4);
                    return ParseHeaderBlock(headerText);
                }
            }
        }
    }

    private static Dictionary<string, string> ParseHeaderBlock(string headerBlock)
    {
        var headers = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        using var reader = new StringReader(headerBlock);
        string? line;
        while ((line = reader.ReadLine()) is not null)
        {
            if (string.IsNullOrWhiteSpace(line))
            {
                continue;
            }

            var idx = line.IndexOf(':');
            if (idx <= 0)
            {
                continue;
            }

            var name = line[..idx].Trim();
            var value = line[(idx + 1)..].Trim();
            headers[name] = value;
        }

        return headers;
    }
}
