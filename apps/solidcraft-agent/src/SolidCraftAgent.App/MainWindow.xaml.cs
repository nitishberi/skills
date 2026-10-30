using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using SolidCraftAgent.App.Views;

namespace SolidCraftAgent.App;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        ExtendsContentIntoTitleBar = true;
        NavView.SelectedItem = NavView.MenuItems[0];
        ContentFrame.Navigate(typeof(SessionPage));
    }

    private void NavView_SelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
    {
        if (args.SelectedItem is not NavigationViewItem item || item.Tag is not string tag)
        {
            return;
        }

        var pageType = tag switch
        {
            "Session" => typeof(SessionPage),
            "Lessons" => typeof(LessonsPage),
            "Settings" => typeof(SettingsPage),
            _ => typeof(SessionPage),
        };
        ContentFrame.Navigate(pageType);
    }
}
