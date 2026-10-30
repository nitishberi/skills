namespace SolidCraftAgent.Core.Lessons;

public interface ILessonStore
{
    Task EnsureSeededAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Lesson>> ListAsync(LessonStatus? status = null, CancellationToken cancellationToken = default);

    Task<Lesson> AppendPendingAsync(string title, string body, string? source = null, CancellationToken cancellationToken = default);

    Task ApproveAsync(string id, CancellationToken cancellationToken = default);

    Task RejectAsync(string id, CancellationToken cancellationToken = default);

    Task FoldAsync(IReadOnlyList<string> ids, CancellationToken cancellationToken = default);

    Task<string> BuildActiveLessonsPromptSectionAsync(CancellationToken cancellationToken = default);

    string LessonsMarkdownPath { get; }

    string SqlitePath { get; }
}
