using SolidCraftAgent.Llm.Providers;

namespace SolidCraftAgent.Core.Tests;

public class LlmResponseParsingTests
{
    [Fact]
    public void OpenAiCompatible_ParsesToolCalls()
    {
        var raw =
            """
            {
              "choices": [
                {
                  "finish_reason": "tool_calls",
                  "message": {
                    "role": "assistant",
                    "content": null,
                    "tool_calls": [
                      {
                        "id": "call_1",
                        "type": "function",
                        "function": { "name": "new_design", "arguments": "{\"name\":\"part\"}" }
                      }
                    ]
                  }
                }
              ]
            }
            """;
        var response = OpenAiCompatibleChatProvider.ParseResponse(raw);
        Assert.Single(response.ToolCalls);
        Assert.Equal("new_design", response.ToolCalls[0].Name);
        Assert.Contains("part", response.ToolCalls[0].ArgumentsJson);
    }

    [Fact]
    public void Claude_ParsesToolUseBlocks()
    {
        var raw =
            """
            {
              "stop_reason": "tool_use",
              "content": [
                { "type": "text", "text": "Creating design" },
                {
                  "type": "tool_use",
                  "id": "toolu_1",
                  "name": "document.units",
                  "input": { "units": "mm" }
                }
              ]
            }
            """;
        var response = ClaudeChatProvider.ParseResponse(raw);
        Assert.Equal("Creating design", response.Content);
        Assert.Single(response.ToolCalls);
        Assert.Equal("document.units", response.ToolCalls[0].Name);
        Assert.Contains("mm", response.ToolCalls[0].ArgumentsJson);
    }
}
