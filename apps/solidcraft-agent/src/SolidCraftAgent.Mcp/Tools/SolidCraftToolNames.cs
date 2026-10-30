namespace SolidCraftAgent.Mcp.Tools;

/// <summary>
/// Known SolidCraft MCP tool names from the modelling history surface.
/// Actual servers may expose additional tools discovered via tools/list.
/// </summary>
public static class SolidCraftToolNames
{
    public const string NewDesign = "new_design";
    public const string DocumentUnits = "document.units";
    public const string Batch = "batch";
    public const string SketchCreate = "sketch.create";
    public const string Save = "save";

    public static readonly IReadOnlyList<string> CoreTools =
    [
        NewDesign,
        DocumentUnits,
        SketchCreate,
        Batch,
        Save,
    ];
}
