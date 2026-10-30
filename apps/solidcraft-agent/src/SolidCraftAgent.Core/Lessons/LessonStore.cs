using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.Data.Sqlite;
using SolidCraftAgent.Core.Seed;

namespace SolidCraftAgent.Core.Lessons;

/// <summary>
/// Append-only lessons.md plus SQLite index (status: seed/pending/approved/folded/rejected).
/// </summary>
public sealed class LessonStore : ILessonStore, IAsyncDisposable
{
    private static readonly Regex SeedSectionRegex = new(
        @"^##\s+(?<id>L\d+)\s+-\s+(?<title>.+)$",
        RegexOptions.Multiline | RegexOptions.Compiled);

    private readonly string _dataDirectory;
    private readonly SemaphoreSlim _gate = new(1, 1);
    private bool _seeded;

    public LessonStore(string dataDirectory)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(dataDirectory);
        _dataDirectory = dataDirectory;
        Directory.CreateDirectory(_dataDirectory);
        LessonsMarkdownPath = Path.Combine(_dataDirectory, "lessons.md");
        SqlitePath = Path.Combine(_dataDirectory, "lessons.db");
    }

    public string LessonsMarkdownPath { get; }

    public string SqlitePath { get; }

    public async Task EnsureSeededAsync(CancellationToken cancellationToken = default)
    {
        await _gate.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            await InitializeSchemaAsync(cancellationToken).ConfigureAwait(false);
            if (_seeded)
            {
                return;
            }

            var count = await ScalarLongAsync("SELECT COUNT(1) FROM lessons;", cancellationToken).ConfigureAwait(false);
            if (count == 0)
            {
                var seedMarkdown = SeedResourceLoader.LoadText("lessons-seed.md");
                if (!File.Exists(LessonsMarkdownPath))
                {
                    await File.WriteAllTextAsync(LessonsMarkdownPath, seedMarkdown, cancellationToken).ConfigureAwait(false);
                }

                foreach (var lesson in ParseSeedLessons(seedMarkdown))
                {
                    await InsertAsync(lesson, appendMarkdown: false, cancellationToken).ConfigureAwait(false);
                }
            }

            _seeded = true;
        }
        finally
        {
            _gate.Release();
        }
    }

    public async Task<IReadOnlyList<Lesson>> ListAsync(LessonStatus? status = null, CancellationToken cancellationToken = default)
    {
        await EnsureSeededAsync(cancellationToken).ConfigureAwait(false);
        await _gate.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            await using var connection = OpenConnection();
            await connection.OpenAsync(cancellationToken).ConfigureAwait(false);
            var sql = status is null
                ? "SELECT id, title, body, status, created_at, updated_at, source FROM lessons ORDER BY created_at ASC;"
                : "SELECT id, title, body, status, created_at, updated_at, source FROM lessons WHERE status = $status ORDER BY created_at ASC;";
            await using var cmd = connection.CreateCommand();
            cmd.CommandText = sql;
            if (status is not null)
            {
                cmd.Parameters.AddWithValue("$status", status.Value.ToString());
            }

            var list = new List<Lesson>();
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken).ConfigureAwait(false);
            while (await reader.ReadAsync(cancellationToken).ConfigureAwait(false))
            {
                list.Add(ReadLesson(reader));
            }

            return list;
        }
        finally
        {
            _gate.Release();
        }
    }

    public async Task<Lesson> AppendPendingAsync(
        string title,
        string body,
        string? source = null,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(title);
        ArgumentException.ThrowIfNullOrWhiteSpace(body);
        await EnsureSeededAsync(cancellationToken).ConfigureAwait(false);

        var lesson = new Lesson
        {
            Id = "P" + DateTimeOffset.UtcNow.ToString("yyyyMMddHHmmssfff", CultureInfo.InvariantCulture),
            Title = title.Trim(),
            Body = body.Trim(),
            Status = LessonStatus.Pending,
            CreatedAt = DateTimeOffset.UtcNow,
            Source = source,
        };

        await _gate.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            await InsertAsync(lesson, appendMarkdown: true, cancellationToken).ConfigureAwait(false);
            return lesson;
        }
        finally
        {
            _gate.Release();
        }
    }

    public Task ApproveAsync(string id, CancellationToken cancellationToken = default) =>
        SetStatusAsync(id, LessonStatus.Approved, cancellationToken);

    public Task RejectAsync(string id, CancellationToken cancellationToken = default) =>
        SetStatusAsync(id, LessonStatus.Rejected, cancellationToken);

    public async Task FoldAsync(IReadOnlyList<string> ids, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(ids);
        await EnsureSeededAsync(cancellationToken).ConfigureAwait(false);
        await _gate.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            foreach (var id in ids)
            {
                await SetStatusUnlockedAsync(id, LessonStatus.Folded, cancellationToken).ConfigureAwait(false);
            }

            var foldNote =
                $"{Environment.NewLine}{Environment.NewLine}## Fold {DateTimeOffset.UtcNow:yyyy-MM-dd}{Environment.NewLine}" +
                $"Folded lesson ids: {string.Join(", ", ids)}{Environment.NewLine}";
            await File.AppendAllTextAsync(LessonsMarkdownPath, foldNote, cancellationToken).ConfigureAwait(false);
        }
        finally
        {
            _gate.Release();
        }
    }

    public async Task<string> BuildActiveLessonsPromptSectionAsync(CancellationToken cancellationToken = default)
    {
        var lessons = await ListAsync(cancellationToken: cancellationToken).ConfigureAwait(false);
        var active = lessons
            .Where(l => l.Status is LessonStatus.Seed or LessonStatus.Approved)
            .ToList();

        if (active.Count == 0)
        {
            return "(no active lessons)";
        }

        var sb = new StringBuilder();
        foreach (var lesson in active)
        {
            sb.AppendLine($"### {lesson.Id}: {lesson.Title}");
            sb.AppendLine(lesson.Body);
            sb.AppendLine();
        }

        return sb.ToString().TrimEnd();
    }

    internal static IReadOnlyList<Lesson> ParseSeedLessons(string markdown)
    {
        var matches = SeedSectionRegex.Matches(markdown);
        var lessons = new List<Lesson>();
        for (var i = 0; i < matches.Count; i++)
        {
            var match = matches[i];
            var start = match.Index;
            var end = i + 1 < matches.Count ? matches[i + 1].Index : markdown.Length;
            var block = markdown[start..end].Trim();
            var id = match.Groups["id"].Value;
            var title = match.Groups["title"].Value.Trim();
            lessons.Add(new Lesson
            {
                Id = id,
                Title = title,
                Body = block,
                Status = LessonStatus.Seed,
                CreatedAt = DateTimeOffset.UnixEpoch,
                Source = "seed",
            });
        }

        return lessons;
    }

    private async Task SetStatusAsync(string id, LessonStatus status, CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(id);
        await EnsureSeededAsync(cancellationToken).ConfigureAwait(false);
        await _gate.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            await SetStatusUnlockedAsync(id, status, cancellationToken).ConfigureAwait(false);
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task SetStatusUnlockedAsync(string id, LessonStatus status, CancellationToken cancellationToken)
    {
        await using var connection = OpenConnection();
        await connection.OpenAsync(cancellationToken).ConfigureAwait(false);
        await using var cmd = connection.CreateCommand();
        cmd.CommandText = "UPDATE lessons SET status = $status, updated_at = $updated WHERE id = $id;";
        cmd.Parameters.AddWithValue("$status", status.ToString());
        cmd.Parameters.AddWithValue("$updated", DateTimeOffset.UtcNow.ToString("O"));
        cmd.Parameters.AddWithValue("$id", id);
        var rows = await cmd.ExecuteNonQueryAsync(cancellationToken).ConfigureAwait(false);
        if (rows == 0)
        {
            throw new KeyNotFoundException($"Lesson '{id}' was not found.");
        }
    }

    private async Task InsertAsync(Lesson lesson, bool appendMarkdown, CancellationToken cancellationToken)
    {
        await using var connection = OpenConnection();
        await connection.OpenAsync(cancellationToken).ConfigureAwait(false);
        await using var cmd = connection.CreateCommand();
        cmd.CommandText =
            """
            INSERT INTO lessons (id, title, body, status, created_at, updated_at, source)
            VALUES ($id, $title, $body, $status, $created, $updated, $source);
            """;
        cmd.Parameters.AddWithValue("$id", lesson.Id);
        cmd.Parameters.AddWithValue("$title", lesson.Title);
        cmd.Parameters.AddWithValue("$body", lesson.Body);
        cmd.Parameters.AddWithValue("$status", lesson.Status.ToString());
        cmd.Parameters.AddWithValue("$created", lesson.CreatedAt.ToString("O"));
        cmd.Parameters.AddWithValue("$updated", (object?)lesson.UpdatedAt?.ToString("O") ?? DBNull.Value);
        cmd.Parameters.AddWithValue("$source", (object?)lesson.Source ?? DBNull.Value);
        await cmd.ExecuteNonQueryAsync(cancellationToken).ConfigureAwait(false);

        if (appendMarkdown)
        {
            var block =
                $"{Environment.NewLine}{Environment.NewLine}## {lesson.Id} - {lesson.Title}{Environment.NewLine}" +
                $"- **Status:** {lesson.Status.ToString().ToLowerInvariant()}{Environment.NewLine}" +
                $"- **Rule:** {lesson.Body}{Environment.NewLine}";
            await File.AppendAllTextAsync(LessonsMarkdownPath, block, cancellationToken).ConfigureAwait(false);
        }
    }

    private async Task InitializeSchemaAsync(CancellationToken cancellationToken)
    {
        await using var connection = OpenConnection();
        await connection.OpenAsync(cancellationToken).ConfigureAwait(false);
        await using var cmd = connection.CreateCommand();
        cmd.CommandText =
            """
            CREATE TABLE IF NOT EXISTS lessons (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              body TEXT NOT NULL,
              status TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NULL,
              source TEXT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_lessons_status ON lessons(status);
            """;
        await cmd.ExecuteNonQueryAsync(cancellationToken).ConfigureAwait(false);
    }

    private async Task<long> ScalarLongAsync(string sql, CancellationToken cancellationToken)
    {
        await using var connection = OpenConnection();
        await connection.OpenAsync(cancellationToken).ConfigureAwait(false);
        await using var cmd = connection.CreateCommand();
        cmd.CommandText = sql;
        var result = await cmd.ExecuteScalarAsync(cancellationToken).ConfigureAwait(false);
        return Convert.ToInt64(result, CultureInfo.InvariantCulture);
    }

    private SqliteConnection OpenConnection() => new($"Data Source={SqlitePath}");

    private static Lesson ReadLesson(SqliteDataReader reader) => new()
    {
        Id = reader.GetString(0),
        Title = reader.GetString(1),
        Body = reader.GetString(2),
        Status = Enum.Parse<LessonStatus>(reader.GetString(3)),
        CreatedAt = DateTimeOffset.Parse(reader.GetString(4), CultureInfo.InvariantCulture),
        UpdatedAt = reader.IsDBNull(5) ? null : DateTimeOffset.Parse(reader.GetString(5), CultureInfo.InvariantCulture),
        Source = reader.IsDBNull(6) ? null : reader.GetString(6),
    };

    public ValueTask DisposeAsync()
    {
        _gate.Dispose();
        return ValueTask.CompletedTask;
    }
}
