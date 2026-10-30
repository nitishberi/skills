using SolidCraftAgent.Llm.Abstractions;

namespace SolidCraftAgent.Core.Config;

public sealed class AppSettings
{
    public LlmSettings Llm { get; set; } = new();

    /// <summary>Executable or command that launches the SolidCraft MCP server (stdio).</summary>
    public string SolidCraftMcpCommand { get; set; } = "solidcraft-mcp";

    public string SolidCraftMcpArguments { get; set; } = string.Empty;

    public string? SolidCraftMcpWorkingDirectory { get; set; }

    /// <summary>Default document units after new_design.</summary>
    public string DefaultUnits { get; set; } = "mm";

    /// <summary>
    /// Permanent folder for .sc saves. SolidCraft temp folders change on server restart.
    /// </summary>
    public string PermanentModelsFolder { get; set; } =
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "SolidCraftModels");

    public string DataDirectory { get; set; } =
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "SolidCraftAgent");

    public string SettingsPath => Path.Combine(DataDirectory, "settings.json");
}
