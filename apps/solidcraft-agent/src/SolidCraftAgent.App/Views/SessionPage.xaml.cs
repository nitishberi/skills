using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using SolidCraftAgent.App.Services;
using SolidCraftAgent.Core.Agent;
using Windows.Storage.Pickers;
using WinRT.Interop;

namespace SolidCraftAgent.App.Views;

public sealed partial class SessionPage : Page
{
    private AgentOrchestrator? _orchestrator;

    public SessionPage()
    {
        InitializeComponent();
        _orchestrator = AppServices.CreateOrchestrator();
        _orchestrator.StepEmitted += (_, step) => DispatcherQueue.TryEnqueue(() =>
        {
            StepList.Items.Insert(0, $"[{step.Kind}] {step.Message}");
        });
        RefreshDrawings();
    }

    private async void AttachDrawing_Click(object sender, RoutedEventArgs e)
    {
        var picker = new FileOpenPicker();
        var hwnd = WindowNative.GetWindowHandle(App.MainWindow);
        InitializeWithWindow.Initialize(picker, hwnd);
        picker.FileTypeFilter.Add(".png");
        picker.FileTypeFilter.Add(".jpg");
        picker.FileTypeFilter.Add(".jpeg");
        picker.FileTypeFilter.Add(".webp");
        picker.FileTypeFilter.Add(".tif");
        picker.FileTypeFilter.Add(".tiff");
        picker.FileTypeFilter.Add(".pdf");
        var file = await picker.PickSingleFileAsync();
        if (file is null || _orchestrator is null)
        {
            return;
        }

        _orchestrator.Transcript.AttachDrawing(file.Path);
        RefreshDrawings();
        AppendChat($"Attached: {file.Path}");
    }

    private async void Preflight_Click(object sender, RoutedEventArgs e)
    {
        if (_orchestrator is null)
        {
            return;
        }

        StatusText.Text = "Running preflight...";
        var findings = await _orchestrator.RunPreflightChecksAsync();
        StatusText.Text = findings[0];
        foreach (var finding in findings)
        {
            AppendChat($"Preflight: {finding}");
        }
    }

    private async void Send_Click(object sender, RoutedEventArgs e)
    {
        if (_orchestrator is null)
        {
            return;
        }

        var text = PromptBox.Text?.Trim();
        if (string.IsNullOrWhiteSpace(text))
        {
            return;
        }

        PromptBox.Text = string.Empty;
        AppendChat($"You: {text}");
        StatusText.Text = "Running...";
        try
        {
            var reply = await _orchestrator.RunUserTurnAsync(text);
            AppendChat($"Agent: {reply}");
            StatusText.Text = "Done";
            var transcriptDir = Path.Combine(AppServices.Settings.DataDirectory, "sessions");
            Directory.CreateDirectory(transcriptDir);
            await _orchestrator.Transcript.SaveAsync(
                Path.Combine(transcriptDir, $"session-{DateTime.UtcNow:yyyyMMdd-HHmmss}.json"));
        }
        catch (Exception ex)
        {
            AppendChat($"Error: {ex.Message}");
            StatusText.Text = "Error";
        }
    }

    private void OpenModel_Click(object sender, RoutedEventArgs e)
    {
        var folder = _orchestrator?.Transcript.LastSavedModelPath is string path
            ? Path.GetDirectoryName(path)
            : AppServices.Settings.PermanentModelsFolder;
        if (string.IsNullOrWhiteSpace(folder))
        {
            return;
        }

        Directory.CreateDirectory(folder);
        System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
        {
            FileName = folder,
            UseShellExecute = true,
        });
    }

    private void RefreshDrawings()
    {
        if (_orchestrator is null)
        {
            return;
        }

        DrawingsText.Text = _orchestrator.Transcript.DrawingPaths.Count == 0
            ? "No drawings attached."
            : "Drawings:\n" + string.Join("\n", _orchestrator.Transcript.DrawingPaths);
    }

    private void AppendChat(string line)
    {
        ChatList.Items.Add(new TextBlock { Text = line, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 0, 0, 8) });
    }
}
