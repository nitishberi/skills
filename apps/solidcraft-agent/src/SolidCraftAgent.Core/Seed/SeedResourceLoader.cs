using System.Reflection;
using System.Text.Json;

namespace SolidCraftAgent.Core.Seed;

public static class SeedResourceLoader
{
    private static readonly Assembly Assembly = typeof(SeedResourceLoader).Assembly;

    public static string LoadText(string fileName)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(fileName);
        var name = Assembly.GetManifestResourceNames()
            .FirstOrDefault(n => n.EndsWith(fileName, StringComparison.OrdinalIgnoreCase))
            ?? throw new FileNotFoundException($"Embedded seed resource '{fileName}' was not found. Available: {string.Join(", ", Assembly.GetManifestResourceNames())}");

        using var stream = Assembly.GetManifestResourceStream(name)
            ?? throw new FileNotFoundException($"Could not open embedded resource '{name}'.");
        using var reader = new StreamReader(stream);
        return reader.ReadToEnd();
    }

    public static T LoadJson<T>(string fileName)
    {
        var json = LoadText(fileName);
        return JsonSerializer.Deserialize<T>(json, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
        }) ?? throw new InvalidOperationException($"Failed to deserialize seed '{fileName}'.");
    }
}
