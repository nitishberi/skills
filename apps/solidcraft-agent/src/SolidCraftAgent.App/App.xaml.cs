using Microsoft.UI.Xaml;
using SolidCraftAgent.App.Services;

namespace SolidCraftAgent.App;

public partial class App : Application
{
    private Window? _window;

    public App()
    {
        InitializeComponent();
        AppServices.Initialize();
    }

    public static Window? MainWindow { get; private set; }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        _window ??= new MainWindow();
        MainWindow = _window;
        _window.Activate();
    }
}
