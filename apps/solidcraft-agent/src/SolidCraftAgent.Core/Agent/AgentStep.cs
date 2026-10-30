namespace SolidCraftAgent.Core.Agent;

public enum AgentStepKind
{
    Info,
    Llm,
    Tool,
    Verify,
    Lesson,
    Error,
    Save,
}

public sealed record AgentStep(
    AgentStepKind Kind,
    string Message,
    DateTimeOffset Timestamp,
    string? Detail = null);
