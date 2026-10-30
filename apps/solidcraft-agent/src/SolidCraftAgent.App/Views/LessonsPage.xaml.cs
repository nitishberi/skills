using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using SolidCraftAgent.App.Services;
using SolidCraftAgent.Core.Lessons;

namespace SolidCraftAgent.App.Views;

public sealed partial class LessonsPage : Page
{
    public LessonsPage()
    {
        InitializeComponent();
        _ = ReloadAsync();
    }

    private async void Refresh_Click(object sender, RoutedEventArgs e) => await ReloadAsync();

    private async void StatusFilter_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (IsLoaded)
        {
            await ReloadAsync();
        }
    }

    private async void Approve_Click(object sender, RoutedEventArgs e)
    {
        foreach (var lesson in SelectedLessons())
        {
            await AppServices.Lessons.ApproveAsync(lesson.Id);
        }

        await ReloadAsync();
    }

    private async void Reject_Click(object sender, RoutedEventArgs e)
    {
        foreach (var lesson in SelectedLessons())
        {
            await AppServices.Lessons.RejectAsync(lesson.Id);
        }

        await ReloadAsync();
    }

    private async void Fold_Click(object sender, RoutedEventArgs e)
    {
        var ids = SelectedLessons().Select(l => l.Id).ToList();
        if (ids.Count == 0)
        {
            return;
        }

        await AppServices.Lessons.FoldAsync(ids);
        await ReloadAsync();
    }

    private IEnumerable<Lesson> SelectedLessons() =>
        LessonList.SelectedItems.OfType<Lesson>();

    private async Task ReloadAsync()
    {
        LessonStatus? status = null;
        if (StatusFilter.SelectedItem is ComboBoxItem item
            && item.Tag is string tag
            && !string.IsNullOrWhiteSpace(tag)
            && Enum.TryParse<LessonStatus>(tag, out var parsed))
        {
            status = parsed;
        }

        var lessons = await AppServices.Lessons.ListAsync(status);
        LessonList.ItemsSource = lessons;
    }
}
