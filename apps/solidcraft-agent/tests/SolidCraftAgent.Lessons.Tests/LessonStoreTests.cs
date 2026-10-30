using SolidCraftAgent.Core.Lessons;
using SolidCraftAgent.Core.Seed;

namespace SolidCraftAgent.Lessons.Tests;

public class LessonStoreTests
{
    [Fact]
    public void ParseSeedLessons_FindsSevenSeededLessons()
    {
        var markdown = SeedResourceLoader.LoadText("lessons-seed.md");
        var lessons = LessonStore.ParseSeedLessons(markdown);
        Assert.Equal(7, lessons.Count);
        Assert.Equal("L001", lessons[0].Id);
        Assert.Equal("L007", lessons[^1].Id);
        Assert.All(lessons, l => Assert.Equal(LessonStatus.Seed, l.Status));
    }

    [Fact]
    public async Task EnsureSeeded_Approve_Fold_AndActivePrompt()
    {
        var dir = Path.Combine(Path.GetTempPath(), "solidcraft-lessons-" + Guid.NewGuid().ToString("N"));
        await using var store = new LessonStore(dir);
        await store.EnsureSeededAsync();

        var seeded = await store.ListAsync(LessonStatus.Seed);
        Assert.Equal(7, seeded.Count);

        var pending = await store.AppendPendingAsync(
            "Thickness mapping reminder",
            "Always match thickness callouts to the labelled feature.");
        Assert.Equal(LessonStatus.Pending, pending.Status);

        await store.ApproveAsync(pending.Id);
        var approved = await store.ListAsync(LessonStatus.Approved);
        Assert.Contains(approved, l => l.Id == pending.Id);

        var prompt = await store.BuildActiveLessonsPromptSectionAsync();
        Assert.Contains("L001", prompt);
        Assert.Contains(pending.Id, prompt);

        await store.FoldAsync([pending.Id]);
        var folded = await store.ListAsync(LessonStatus.Folded);
        Assert.Contains(folded, l => l.Id == pending.Id);

        var promptAfterFold = await store.BuildActiveLessonsPromptSectionAsync();
        Assert.DoesNotContain(pending.Id, promptAfterFold);
        Assert.Contains("L001", promptAfterFold);

        Assert.True(File.Exists(store.LessonsMarkdownPath));
        Assert.True(File.Exists(store.SqlitePath));
    }

    [Fact]
    public async Task Reject_RemovesFromActivePrompt()
    {
        var dir = Path.Combine(Path.GetTempPath(), "solidcraft-lessons-" + Guid.NewGuid().ToString("N"));
        await using var store = new LessonStore(dir);
        await store.EnsureSeededAsync();
        var pending = await store.AppendPendingAsync("Bad lesson", "Should be rejected.");
        await store.RejectAsync(pending.Id);
        var prompt = await store.BuildActiveLessonsPromptSectionAsync();
        Assert.DoesNotContain(pending.Id, prompt);
    }
}
