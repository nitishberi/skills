using SolidCraftAgent.Core.Lessons;

namespace SolidCraftAgent.Core.Seed;

public sealed class SystemPromptBuilder
{
    private readonly ILessonStore _lessons;

    public SystemPromptBuilder(ILessonStore lessons)
    {
        _lessons = lessons;
    }

    public async Task<string> BuildAsync(CancellationToken cancellationToken = default)
    {
        var template = SeedResourceLoader.LoadText("system-prompt.md");
        var active = await _lessons.BuildActiveLessonsPromptSectionAsync(cancellationToken).ConfigureAwait(false);
        var workarounds = SeedResourceLoader.LoadText("kernel-workarounds.json");
        var tapDrills = SeedResourceLoader.LoadText("tap-drill-table.json");
        var checks = SeedResourceLoader.LoadText("verification-checks.json");

        return template
            .Replace("{{ACTIVE_LESSONS}}", active, StringComparison.Ordinal)
            + """

## Kernel workarounds (JSON)
"""
            + workarounds
            + """

## Tap-drill table (JSON)
"""
            + tapDrills
            + """

## Verification checks (JSON)
"""
            + checks;
    }
}
