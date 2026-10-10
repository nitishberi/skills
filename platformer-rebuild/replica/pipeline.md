# Replica pipeline

## Target

- **Name / URL:** Super Mario Bros (NES-era core loop); public wiki + trailers only
- **Class:** `game`
- **Platforms in scope:** Godot 4.3 desktop, macOS export
- **Slice (in):** run, jump, power-ups, levels, bosses, lives/continues
- **Slice (out):** multiplayer; ROM/binary; Nintendo characters/art/music/names
- **Implementation target:** Pipe Hop (Godot 4) + macOS export preset
- **Use:** personal (not for sale)

## Stages

| # | Stage | Status | Outputs |
| -: | --- | --- | --- |
| 1 | replica-recon | done | `recon.md`, `features.csv` |
| 2 | replica-architect | done | `architecture.md` |
| 3 | game design | done | `game-design/gdd.md` |
| 4 | replica-design | done | `design/tokens.json`, `design/components.md` |
| 5 | implement | done | `game/` Worlds 1–2 |
| 6 | feel | done | Pixel art, parallax, chiptune SFX/BGM, camera shake, FX |
| 7 | replica-test | done | `test-plan.md`, `bugs.md`, headless smoke |
| 8 | replica-diff | done | `parity.md` (**100 / 100**, must-haves complete) |
| 9 | replica-entrepreneur | skipped | `fixes.md` (personal; no fake reviews) |
| 10 | replica-brand | done | `brand.md`, `brand.json`, sweep **clean** |
| 11 | replica-launch | skipped | `launch/personal.md` (not selling) |
| 12 | ship | done | `game/export_presets.cfg` (templates on user Mac) |

## Skips (intentional)

- Multiplayer; hammer-throwers; fireproof beetle; vine bonus
- Store launch / entrepreneur review mining
- Nintendo IP in any form

## Log

- 2026-10-09: game playable end-to-end
- 2026-10-09: replica stage artifacts completed; parity 100; brand sweep clean
- 2026-10-10: polish pass: `Art`/`Music` autoloads, sprites, parallax, exports rebuilt
- 2026-10-10: SMB1 feel pass: `smb_tuning.gd`, `smb-mechanics.md` (Mario Wiki–aligned rules, clean-room)
