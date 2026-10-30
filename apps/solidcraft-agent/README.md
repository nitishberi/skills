# SolidCraft Agent (v1)

Native **WinUI 3 + .NET 8** Windows app: drawing + chat → SolidCraft model via the local SolidCraft MCP, with switchable LLMs and durable teachable lessons.

This folder is a greenfield app under `apps/solidcraft-agent/`. It does **not** register as a skill bucket or Claude plugin entry.

## Solution layout

| Project | TFM | Role |
|---|---|---|
| `src/SolidCraftAgent.App` | `net8.0-windows10.0.19041.0` | WinUI shell: Session, Lessons, Settings |
| `src/SolidCraftAgent.Core` | `net8.0` | Orchestrator, lessons store, seed prompt, verification math |
| `src/SolidCraftAgent.Llm` | `net8.0` | `IChatProvider` for Claude / OpenAI / OpenAI-compatible local |
| `src/SolidCraftAgent.Mcp` | `net8.0` | stdio MCP JSON-RPC client + tool bridge |
| `src/SolidCraftAgent.Secrets` | `net8.0` | Credential Manager abstraction + test fallbacks |
| `tests/*` | `net8.0` | Framing, lessons, orchestrator preflight, LLM parse tests |

Seed data (7 lessons, tap drills, kernel workarounds, verification checks) lives in `data/` and is embedded into Core.

## Docs

- [Windows setup](docs/WINDOWS-SETUP.md): SolidCraft MCP path, permanent save folder, LLM config, what is Windows-only vs unit-testable.

## Quick commands

```powershell
# Libraries + unit tests (also works on Linux CI; no WinUI restore)
dotnet test SolidCraftAgent.Libraries.slnf

# Full Windows app
dotnet build src/SolidCraftAgent.App/SolidCraftAgent.App.csproj -p:Platform=x64
```


## Plan todos covered

1. **scaffold-winui** - Session / Lessons / Settings navigation and pages
2. **llm-switch** - Claude, OpenAI, OpenAI-compatible; keys via secret store
3. **mcp-client** - stdio MCP client, batch all-or-nothing, kernel errors to chat
4. **agent-loop** - orchestrator + seed prompt / checks from modelling history
5. **lessons-ui** - `lessons.md` + SQLite, approve / reject / fold, active prompt injection
6. **windows-setup** - this README + `docs/WINDOWS-SETUP.md`
