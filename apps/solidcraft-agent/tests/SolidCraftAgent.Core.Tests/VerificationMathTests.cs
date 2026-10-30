using SolidCraftAgent.Core.Seed;

namespace SolidCraftAgent.Core.Tests;

public class VerificationMathTests
{
    [Fact]
    public void Bevel_50x60_On_1_0_Plate_MatchesHistory()
    {
        var bevel = VerificationMath.ComputeBevel(0.5, 60, 1.0);
        Assert.Equal(0.5, bevel.Width);
        Assert.Equal(0.8660254037844386, bevel.Depth, 12);
        Assert.Equal(0.1339745962155614, bevel.Flat, 12);
        Assert.True(VerificationMath.IsFullThicknessCutMistakenForWidth(0.577, 1.0, 60));
        Assert.False(VerificationMath.IsFullThicknessCutMistakenForWidth(0.50, 1.0, 60));
    }

    [Fact]
    public void SystemPrompt_IncludesActiveLessonsPlaceholderReplacement()
    {
        var dir = Path.Combine(Path.GetTempPath(), "solidcraft-prompt-" + Guid.NewGuid().ToString("N"));
        var store = new SolidCraftAgent.Core.Lessons.LessonStore(dir);
        store.EnsureSeededAsync().GetAwaiter().GetResult();
        var builder = new SystemPromptBuilder(store);
        var prompt = builder.BuildAsync().GetAwaiter().GetResult();
        Assert.DoesNotContain("{{ACTIVE_LESSONS}}", prompt);
        Assert.Contains("L001", prompt);
        Assert.Contains("tap-drill", prompt, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("bevel", prompt, StringComparison.OrdinalIgnoreCase);
    }
}
