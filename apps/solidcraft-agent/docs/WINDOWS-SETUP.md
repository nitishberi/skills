# SolidCraft Agent: Windows setup

Native WinUI 3 (.NET 8) app that drives **SolidCraft on this PC** through its MCP server, with switchable LLM providers and a durable lessons store.

Full build and end-to-end runs require **Windows** with SolidCraft installed. Core libraries (`SolidCraftAgent.Core`, `.Llm`, `.Mcp`, `.Secrets`) target `net8.0` and can be unit-tested on Linux CI without WinUI or SolidCraft.

## Prerequisites

1. Windows 10 version 1809+ (or Windows 11).
2. [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0).
3. [Windows App SDK](https://learn.microsoft.com/windows/apps/windows-app-sdk/) workload (Visual Studio 2022 with "Windows application development", or the standalone Windows App SDK runtime/installer).
4. SolidCraft desktop + its **MCP server** already working (the same stdio MCP surface used in the modelling history session: `new_design`, `document.units`, sketches, solids, `batch`, save).
5. An LLM API key (Claude and/or OpenAI) **or** a local OpenAI-compatible server (Ollama / LM Studio).

## Build and run (Windows)

```powershell
cd apps\solidcraft-agent
dotnet restore SolidCraftAgent.sln
dotnet build SolidCraftAgent.sln -c Debug -p:Platform=x64
dotnet run --project src\SolidCraftAgent.App\SolidCraftAgent.App.csproj -c Debug -p:Platform=x64
```

The app is configured as **unpackaged** (`WindowsPackageType=None`) so you can F5 without MSIX signing for local development.

## Installable Setup.exe (incremental revision)

Each publish bumps `version.json` revision and stamps that into the assembly + installer filename:

- `SolidCraftAgent-Setup-rN.exe` (Inno Setup installer)
- `SolidCraftAgent-rN-win-x64.zip` (portable folder zip)

Local (Windows, with .NET 8 SDK + [Inno Setup 6](https://jrsoftware.org/isinfo.php)):

```powershell
cd apps\solidcraft-agent
powershell -ExecutionPolicy Bypass -File .\scripts\publish-windows.ps1
```

CI: workflow `SolidCraft Agent Windows build` (`.github/workflows/solidcraft-agent-windows.yml`) runs on this branch and uploads the Setup exe as an Actions artifact.

## Unit tests (Windows or Linux)

```powershell
cd apps\solidcraft-agent
dotnet test SolidCraftAgent.sln --filter "FullyQualifiedName!~SolidCraftAgent.App"
```

On Linux, exclude or avoid building `SolidCraftAgent.App` (WinUI). Test only the class libraries:

```bash
dotnet test tests/SolidCraftAgent.Core.Tests
dotnet test tests/SolidCraftAgent.Mcp.Tests
dotnet test tests/SolidCraftAgent.Lessons.Tests
```

## First-run configuration

Open **Settings** in the app:

| Field | What to set |
|---|---|
| Protocol | **Anthropic-compatible API** or **OpenAI-compatible API** (same split as SolidCraft's built-in **Add agent** dialog) |
| Name | Display name (SolidCraft uses e.g. `Anthropic`) |
| Base URL | Anthropic preset: `https://api.anthropic.com/v1` (app posts to `{base}/messages`). Local Anthropic-compatible proxies use their host `/v1`. OpenAI-compatible local: typically `http://127.0.0.1:11434/v1` |
| Model id | Any id the endpoint accepts (cloud Claude models, or a local id such as `qwen3:14b`) |
| Request timeout | SolidCraft default is **300 s** |
| API key | Optional; stored in **Windows Credential Manager** / system keychain, never in settings.json. Leave empty for a local server |
| SolidCraft MCP command | Full path or command that launches the SolidCraft MCP server on stdio |
| MCP arguments / working directory | Whatever your SolidCraft MCP install expects |
| Default units | `mm` (agent also forces units after `new_design`) |
| Permanent save folder | A folder SolidCraft is allowed to write to across MCP restarts (avoid relying only on `%TEMP%\solidcraft-mcp-*`) |

SolidCraft's own **Add agent** UI (Kind: API endpoint, Protocol: Anthropic-compatible API, Preset: Anthropic) is the reference for these fields. Our Settings page mirrors that shape so the same base URL / model / timeout / keychain values transfer cleanly.

### SolidCraft MCP command (from Cursor)

This machine's Cursor MCP config (`%USERPROFILE%\.cursor\mcp.json`) uses:

```json
{
  "mcpServers": {
    "SolidCraft": {
      "command": "C:\\Program Files\\SolidCraft\\solidcraft-cli.exe",
      "args": ["mcp"]
    }
  }
}
```

The app defaults match that: command `C:\Program Files\SolidCraft\solidcraft-cli.exe`, arguments `mcp`. Change Settings only if your install path differs.

If the app cannot start the MCP process, Settings will still save the path; the Session step log will show the launch / initialize error. The agent cannot talk to SolidCraft until that command succeeds.

**Blocker note for cloud agents:** this repository's CI / cloud VMs cannot discover or launch SolidCraft MCP. Only the Windows PC with SolidCraft installed can complete E2E modelling.

## Lessons and data locations

Default data root:

`%LOCALAPPDATA%\SolidCraftAgent\`

| Path | Purpose |
|---|---|
| `settings.json` | Non-secret settings (provider, model, MCP path, save folder) |
| `lessons\lessons.md` | Append-only lessons log |
| `lessons\lessons.db` | SQLite index (status: seed / pending / approved / folded / rejected) |
| `sessions\*.json` | Session transcripts |
| Windows Credential Manager targets `SolidCraftAgent/*` | API keys |

Seed lessons L001-L007, tap-drill table, kernel workarounds, and bevel / thickness verification checks ship embedded from `apps/solidcraft-agent/data/`.

## Workflow reminder

1. Attach a drawing on **Session**.
2. Ask the agent to model the part.
3. Watch the tool / step log for MCP calls and kernel errors (batch is all-or-nothing).
4. On a correction, the agent appends a **pending** lesson; approve it on **Lessons** so the next run injects it into the system prompt. **Fold** marks lessons as packaged into the skill pack after you have reviewed a batch.

## Secrets on non-Windows (tests)

`SecretStoreFactory.CreateDefault()` uses Windows Credential Manager on Windows. On Linux/macOS it falls back to an in-memory store, or a file store under a provided directory. Unit tests use `InMemorySecretStore` / `FileSecretStore` only.
