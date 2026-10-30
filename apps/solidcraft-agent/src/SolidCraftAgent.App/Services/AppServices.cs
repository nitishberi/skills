using SolidCraftAgent.Core.Agent;
using SolidCraftAgent.Core.Config;
using SolidCraftAgent.Core.Lessons;
using SolidCraftAgent.Core.Seed;
using SolidCraftAgent.Llm;
using SolidCraftAgent.Mcp;
using SolidCraftAgent.Secrets;

namespace SolidCraftAgent.App.Services;

public static class AppServices
{
    private static readonly object Gate = new();
    private static bool _initialized;

    public static AppSettings Settings { get; private set; } = new();

    public static ISecretStore Secrets { get; private set; } = new InMemorySecretStore();

    public static ILessonStore Lessons { get; private set; } = null!;

    public static SettingsStore SettingsStore { get; private set; } = null!;

    public static ChatProviderFactory ChatFactory { get; private set; } = null!;

    public static SystemPromptBuilder PromptBuilder { get; private set; } = null!;

    public static HttpClient Http { get; } = new();

    public static void Initialize()
    {
        lock (Gate)
        {
            if (_initialized)
            {
                return;
            }

            var dataDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "SolidCraftAgent");
            Directory.CreateDirectory(dataDir);

            SettingsStore = new SettingsStore(Path.Combine(dataDir, "settings.json"));
            Settings = SettingsStore.LoadAsync().GetAwaiter().GetResult();
            Settings.DataDirectory = dataDir;

            Secrets = SecretStoreFactory.CreateDefault(Path.Combine(dataDir, "secrets"));
            Lessons = new LessonStore(Path.Combine(dataDir, "lessons"));
            Lessons.EnsureSeededAsync().GetAwaiter().GetResult();
            PromptBuilder = new SystemPromptBuilder(Lessons);
            ChatFactory = new ChatProviderFactory(Http, Secrets);
            _initialized = true;
        }
    }

    public static async Task SaveSettingsAsync(CancellationToken cancellationToken = default)
    {
        await SettingsStore.SaveAsync(Settings, cancellationToken).ConfigureAwait(false);
    }

    public static AgentOrchestrator CreateOrchestrator()
    {
        return new AgentOrchestrator(
            Settings,
            Lessons,
            PromptBuilder,
            ChatFactory,
            async ct =>
            {
                var transport = new StdioMcpTransport(
                    Settings.SolidCraftMcpCommand,
                    Settings.SolidCraftMcpArguments,
                    Settings.SolidCraftMcpWorkingDirectory);
                var client = new SolidCraftMcpClient(transport);
                await client.InitializeAsync(ct).ConfigureAwait(false);
                return client;
            });
    }
}
