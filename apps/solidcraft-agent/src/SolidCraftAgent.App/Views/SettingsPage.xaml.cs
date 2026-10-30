using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using SolidCraftAgent.App.Services;
using SolidCraftAgent.Llm.Abstractions;
using SolidCraftAgent.Secrets;

namespace SolidCraftAgent.App.Views;

public sealed partial class SettingsPage : Page
{
    public SettingsPage()
    {
        InitializeComponent();
        _ = LoadAsync();
    }

    private async Task LoadAsync()
    {
        var s = AppServices.Settings;
        SelectProvider(s.Llm.Provider);
        AgentNameBox.Text = s.Llm.AgentName;
        ClaudeBaseBox.Text = s.Llm.ClaudeBaseUrl;
        ClaudeModelBox.Text = s.Llm.ClaudeModel;
        OpenAiModelBox.Text = s.Llm.OpenAiModel;
        OpenAiBaseBox.Text = s.Llm.OpenAiBaseUrl;
        LocalModelBox.Text = s.Llm.OpenAiCompatibleModel;
        LocalBaseBox.Text = s.Llm.OpenAiCompatibleBaseUrl;
        TimeoutBox.Value = s.Llm.RequestTimeoutSeconds;
        McpCommandBox.Text = s.SolidCraftMcpCommand;
        McpArgsBox.Text = s.SolidCraftMcpArguments;
        McpCwdBox.Text = s.SolidCraftMcpWorkingDirectory ?? string.Empty;
        UnitsBox.Text = s.DefaultUnits;
        ModelsFolderBox.Text = s.PermanentModelsFolder;

        ClaudeKeyBox.Password = await AppServices.Secrets.GetAsync(SecretKeys.ClaudeApiKey) ?? string.Empty;
        OpenAiKeyBox.Password = await AppServices.Secrets.GetAsync(SecretKeys.OpenAiApiKey) ?? string.Empty;
        LocalKeyBox.Password = await AppServices.Secrets.GetAsync(SecretKeys.OpenAiCompatibleApiKey) ?? string.Empty;
    }

    private void ProviderBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        // Selection is applied on save.
    }

    private async void Save_Click(object sender, RoutedEventArgs e)
    {
        var s = AppServices.Settings;
        s.Llm.Provider = ReadProvider();
        s.Llm.AgentName = AgentNameBox.Text.Trim();
        s.Llm.ClaudeBaseUrl = ClaudeBaseBox.Text.Trim();
        s.Llm.ClaudeModel = ClaudeModelBox.Text.Trim();
        s.Llm.OpenAiModel = OpenAiModelBox.Text.Trim();
        s.Llm.OpenAiBaseUrl = OpenAiBaseBox.Text.Trim();
        s.Llm.OpenAiCompatibleModel = LocalModelBox.Text.Trim();
        s.Llm.OpenAiCompatibleBaseUrl = LocalBaseBox.Text.Trim();
        s.Llm.RequestTimeoutSeconds = double.IsNaN(TimeoutBox.Value) ? 300 : (int)TimeoutBox.Value;
        s.SolidCraftMcpCommand = McpCommandBox.Text.Trim();
        s.SolidCraftMcpArguments = McpArgsBox.Text.Trim();
        s.SolidCraftMcpWorkingDirectory = string.IsNullOrWhiteSpace(McpCwdBox.Text) ? null : McpCwdBox.Text.Trim();
        s.DefaultUnits = UnitsBox.Text.Trim();
        s.PermanentModelsFolder = ModelsFolderBox.Text.Trim();

        await SetSecretAsync(SecretKeys.ClaudeApiKey, ClaudeKeyBox.Password);
        await SetSecretAsync(SecretKeys.OpenAiApiKey, OpenAiKeyBox.Password);
        await SetSecretAsync(SecretKeys.OpenAiCompatibleApiKey, LocalKeyBox.Password);
        await AppServices.SaveSettingsAsync();
        SaveStatus.Text = "Saved.";
    }

    private static async Task SetSecretAsync(string key, string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            await AppServices.Secrets.DeleteAsync(key);
            return;
        }

        await AppServices.Secrets.SetAsync(key, value);
    }

    private void SelectProvider(LlmProviderKind kind)
    {
        foreach (var item in ProviderBox.Items.OfType<ComboBoxItem>())
        {
            if (string.Equals(item.Tag as string, kind.ToString(), StringComparison.Ordinal))
            {
                ProviderBox.SelectedItem = item;
                return;
            }
        }

        ProviderBox.SelectedIndex = 0;
    }

    private LlmProviderKind ReadProvider()
    {
        if (ProviderBox.SelectedItem is ComboBoxItem item
            && item.Tag is string tag
            && Enum.TryParse<LlmProviderKind>(tag, out var kind))
        {
            return kind;
        }

        return LlmProviderKind.Claude;
    }
}
