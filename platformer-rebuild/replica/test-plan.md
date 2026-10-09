# Test plan: Pipe Hop

Generated from `replica/recon.md` flows. Headless scene loads are automated; play cases are manual on Godot desktop/macOS.

## Automation (done)

- Headless `--scene` smoke for title, all 8 stages, bonus, stage_clear, world_clear, game_over (2026-10-09): pass

## F01 Clear overworld stage

| ID | case | expected |
| --- | --- | --- |
| F01-H1 | Start → 1-1 → flag | stage clear tally → 1-2 |
| F01-E1 | Fall in pit | lose life → fanfare |
| F01-E2 | Time = 0 | lose life |
| F01-E3 | Pause Esc mid-run | freeze; Esc resumes |

## F02 Power ladder

| ID | case | expected |
| --- | --- | --- |
| F02-H1 | Bump Big Berry | tall form |
| F02-H2 | Bump Ember Bloom | fire; Shift shoots |
| F02-H3 | Spark Star | invuln contact KO |
| F02-E1 | Hit while tall | shrink + i-frames |
| F02-E2 | Hit while small | death |

## F03 Death and lives

| ID | case | expected |
| --- | --- | --- |
| F03-H1 | 3 deaths | game over |
| F03-H2 | Game over + C | continue world |
| F03-E1 | 100 coins | +1 life |

## F04 Castle boss

| ID | case | expected |
| --- | --- | --- |
| F04-H1 | 1-4 axe | impostor defeated; world 1 clear |
| F04-H2 | 2-4 axe or 8 embers | final Duke; world 2 clear |
| F04-N1 | Stomp Duke | take damage |

## F05 Shortcuts

| ID | case | expected |
| --- | --- | --- |
| F05-H1 | ↓ on 1-1 pipe | bonus coins; exit returns near pipe |
| F05-H2 | Touch 1-1 warp | jump to W2-1 |

## Brand / IP

| ID | case | expected |
| --- | --- | --- |
| IP-1 | sweep.py | clean |
| IP-2 | On-screen strings | Pipe Hop / Cap / Duke only |
