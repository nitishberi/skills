# Architecture: Pipe Hop (SMB-style mechanics, intentionally a bit off)

Personal-use rebuild of NES-era side-scroll platformer mechanics. Not for sale.
Similar feel; names, palette, and art are deliberately off Nintendo IP.

## Stack

| layer | choice | why |
| --- | --- | --- |
| engine | Godot 4.3 (GDScript) | 2D first-class, macOS export, free |
| physics | CharacterBody2D + TileMapLayer | standard platformer path |
| stage data | packed scenes + simple JSON later | vertical slice uses hand-built Level_1_1 |
| audio | original placeholders (silent/beeps later) | no Nintendo audio |
| art | ColorRect / Polygon2D primitives first, then original pixel art | similar silhouettes, off colors |
| save | none in slice (RunState in autoload) | lives/score in memory |
| export | macOS .app via Godot export templates (user machine) | cloud Linux validates headless |

## Working brand (temporary, pre replica-brand)

| role | our name | note |
| --- | --- | --- |
| game | Pipe Hop | not a Nintendo title |
| player | Cap | red-orange overalls vibe avoided; teal cap + mustard suit |
| walker enemy | Browncap | round walker, brown/cream |
| shell enemy | Shellbug | green shell, kicks |
| grow pickup | Big Berry | grows Cap one size |
| fire pickup | Ember Bloom | unlocks ember shots |
| invuln | Spark Star | timed invuln |
| castle boss | Duke Spikes | axe-bridge clear |
| palette | sky `#7ec8e3`, ground `#5a3d2b`, accent `#e8a838` | off classic blue/red/green block look |

## Runtime model (not SQL)

Autoload `RunState`:
- lives, score, coins, world, stage, time_left, form (`small`|`tall`|`fire`), invuln_timer

Stage scenes:
- `res://scenes/stages/level_1_1.tscn` (vertical slice)
- later: level_W_S.tscn or data-driven TileMap

Scenes / routes (game flow):

| scene | recon | purpose |
| --- | --- | --- |
| `Title.tscn` | S01 | Start → life fanfare |
| `LifeFanfare.tscn` | S02 | show world-stage + lives |
| `Stage.tscn` base | S03 | gameplay host |
| HUD CanvasLayer | S04 | score/coins/world/time |
| Pause overlay | S05 | later |
| `CastleBoss` stub | S08 | after slice |
| GameOver | S11 | lives == 0 |

## Physics / layers

| layer bit | name | collides with |
| --- | --- | --- |
| 1 | world | player, enemies, pickups |
| 2 | player | world, enemies, pickups, goal |
| 3 | enemies | world, player, shell |
| 4 | pickups | player, world |
| 5 | hazards | player |
| 6 | goal | player |

## The parts that bite

- **Jump feel:** acceleration, friction, coyote/jump-buffer light touch so it feels snappy without copying Nintendo code
- **Right-only camera:** Camera2D limit_left follows max X reached
- **One pickup on screen:** despawn previous world item when a new one spawns
- **Form change hitboxes:** tall Caps taller collision; squeeze under 1-tile gaps when small
- **Shell kick races:** deferred physics queries when kicking Shellbug
- **macOS export:** export templates installed on the Mac that builds the .app

## Build order

1. **Vertical slice (now):** Title → LifeFanfare → Level 1-1 with Cap run/jump, Browncaps, Big Berry, coins, goal flag, lives/HUD/timer, death/restart
2. **Must-haves:** Ember Bloom, Spark Star, Shellbug, brick/question blocks, more stages, Duke Spikes castles
3. **Should-haves:** pipes/bonus, warp, water, pause, continue
4. **Brand polish:** replica-brand rename if shipping beyond personal folder; original pixel art pass

## Definition of done (personal build)

- [x] Cap runs and variable-height jumps (+ swim)
- [x] Right-only camera + shake
- [x] Browncap / Shellbug / HazardPlant / CloudDropper / Duke Spikes
- [x] Big Berry, Ember Bloom, Spark Star, One-Up
- [x] Worlds 1-2 (8 stages), warp, pipes/bonus, pause, continue, Hard Quest
- [x] Stage-clear tally + original beep SFX
- [x] macOS export preset
- [x] No Nintendo names in code or on-screen strings
