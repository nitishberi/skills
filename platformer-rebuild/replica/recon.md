# Recon map: SMB-style side-scroller (Godot / macOS)

Scope: run, jump, power-ups, levels, bosses, lives (no multiplayer). Full level set in the NES-era pattern (worlds × stages), rebuilt as original content.
For: a clean-room platformer the user can ship on macOS under a new brand.
Date: 2026-10-09

Reference product (evidence only): Super Mario Bros (NES, 1985). Clone-facing names use generic roles. Nintendo characters, art, music, and product names are out of scope for the clone (see Out of scope and `features.csv` skip rows).

## Sources

| # | source | URL | notes |
| --- | --- | --- | --- |
| 1 | Wikipedia overview | https://en.wikipedia.org/wiki/Super_Mario_Bros. | worlds/levels, lives, power ladder, castle boss summary |
| 2 | Super Mario Wiki (game page) | https://www.mariowiki.com/Super_Mario_Bros. | level structure, blocks, pipes, warp zones, castle endings |
| 3 | Wikibooks gameplay | https://en.wikibooks.org/wiki/Super_Mario_Bros./Gameplay | grow/fire behavior, death conditions, level counts |
| 4 | NES instruction manual (hosted transcript) | https://www.world-of-nintendo.com/manuals/nes/super_mario_bros.shtml | enemy defeat rules, death causes, scoring as published |
| 5 | Mario Wiki / Fandom game page | https://mario.fandom.com/wiki/Super_Mario_Bros. | castle boss axe/fireball clear, power-up spawn rules |
| 6 | Official / published trailers & longplays | search: "Super Mario Bros NES gameplay" on public video hosts | camera scroll, jump timing, HUD layout (watch only; no asset rip) |

No ROM, no account, no private APIs, no sprite/audio downloads.

## Core loop

Run and jump through a side-scrolling obstacle course, use power-ups to survive hits and clear threats, reach the stage end before time runs out, spend lives on failure, and defeat a castle boss at the end of each world.

## Screens

Game states treated as screens (S-IDs stable for later stages).

| ID | screen | route / how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| S01 | Title | cold start | start game / show credits stub | logo area (original brand later), Start, options stub | idle, start pressed |
| S02 | Life fanfare | after Start or continue | show world-stage and remaining lives briefly | world label, lives count, Player silhouette | 3s hold then auto-advance |
| S03 | Side-scroll stage | from S02 | core play | Player, TileMap, camera (right-only), HUD overlay | playing, paused, time-low |
| S04 | HUD (overlay on S03) | always in stage | score, coins, world, time, lives cue | Score, Coins, World-Stage, Timer | counting down, time=0 death |
| S05 | Pause | pause input on S03 | freeze play | dim overlay, Pause label | paused / resume |
| S06 | Underground / bonus room | enter pipe or vine | coin room or shortcut segment | alternate tileset, exit pipe | entered, exited mid-stage |
| S07 | Underwater stage variant | certain stage IDs | swim physics variant of S03 | swim controls, water enemies | swimming |
| S08 | Castle / boss stage | world stage 4 | hazards + CastleBoss | bridge, lava, axe/goal, CastleBoss | approach, fight, clear |
| S09 | Stage clear | touch flag/goal or clear boss | score time bonus, advance | flag/goal anim, bonus tally | tallying |
| S10 | Death | hit while small, pit, time out | lose a life, restart fanfare or game over | death anim, blackout | pit, stomp-fail, timeout |
| S11 | Game over | lives = 0 | end run; optional continue-to-world pattern | Game Over label, continue hint | no lives |
| S12 | End / credits stub | clear final castle | win state | thank-you / new quest unlock note | first clear, hard quest unlock |

World map: **out of slice** for NES SMB1 (levels chain directly). Not inventoried as a must screen.

## Flows

```
F01 Clear an overworld stage (run → jump → goal)
    S02 -> S03/S04 -> S09 -> S02 (next stage)
    happy path inputs: hold run, timed jumps, hit blocks, reach goal
    edge: pit death, time=0, camera cannot scroll left, hidden blocks

F02 Power ladder
    S03: small Player hits Grow pickup -> tall Player (brick break, survive one hit)
          tall Player hits Fire pickup -> Fire Player (projectile)
          any form hits Invuln star -> timed contact damage to enemies
    edge: only one world item on screen; hit while powered -> shrink + brief i-frames; pit/time still lethal

F03 Death and lives
    S03 -> S10 -> (lives > 0 ? S02 : S11)
    edge: 100 coins or 1-Up pickup grants life; continue-from-world pattern on game over (should)

F04 Castle boss
    S02 -> S08 -> reach axe/goal or N fireballs -> S09 -> retainer/end beat (original copy later)
    edge: fake bosses worlds 1–7 vs final boss world 8; lava instant death; fire bars

F05 Optional shortcuts
    S03 -> S06 (pipe/vine) -> re-enter S03 ahead; or warp zone to later world
    edge: one-way camera; miss warp forever this run
```

## Components

| component | variants | states | used on |
| --- | --- | --- | --- |
| Player | Small, Tall, Fire | idle, run, jump, fall, swim, duck (tall), hurt i-frames, dead | S03, S06–S08 |
| Camera | right-only scroll | locked left edge, follow Player x | S03, S07, S08 |
| SolidTile | ground, brick, question, hidden, pipe | intact, bumped, broken, emptied | stages |
| Pickup | Grow, Fire, Invuln, 1-Up, Coin | spawning, moving (Grow), static (Fire), collected | stages |
| Walker | ground enemy | walk, stomped/dead | S03 |
| ShellCrawler | green/red AI, winged | walk, shelled, kicked shell, winged | S03 |
| HazardPlant | pipe plant | hidden, peek, bite | S03 |
| Flyer / Spawner | cloud dropper patterns | chase, drop | later worlds |
| Projectile | player fireball, enemy hammer/bill | active, bounce, despawn | S03, S08 |
| CastleBoss | fake / final | pace, jump, spit/hammer patterns, defeated | S08 |
| Goal | flagpole / axe-bridge | untouched, cleared | S03, S08 |
| HUD | score coins world time | updating | S04 |
| LifeBanner | world + lives | showing | S02 |

## Inferred data model

```
RunState  lives, score, coins, world, stage, time_remaining, player_form (small|tall|fire),
          invuln_timer, game_mode (normal|hard_quest)
          evidence: HUD + Wikipedia lives/coins/power summary
          confidence: high

StageDef  id (world, stage), theme (overworld|underground|athletic|castle|water),
          tile_layout_ref, enemy_spawns[], item_blocks[], goal_type (flag|axe),
          time_limit, scroll_mode (right_only)
          evidence: wiki 8×4 structure; manual/wiki themes
          confidence: high

PlayerState  form, position, velocity, facing, on_floor, can_break_bricks,
             can_shoot, i_frames
          evidence: Wikibooks grow/fire; Wikipedia mushroom/fire/star
          confidence: high

EnemyInst  type, position, ai_mode, shelled?, vulnerable_to_stomp, vulnerable_to_fire
          evidence: manual enemy list (behavior only; clone uses generic types)
          confidence: high (behavior), skip names/art

PickupInst  kind (grow|fire|invuln|one_up|coin), motion, source_block_id
          evidence: wiki power-up spawn rules
          confidence: high

BossEncounter  is_final, defeat_mode (axe|fireballs), bridge_state
          evidence: wiki/fandom castle ending
          confidence: high
```

Relationships: RunState 1-1 active StageDef; StageDef 1-n EnemyInst/PickupInst; RunState 1-1 PlayerState; Castle StageDef 0-1 BossEncounter.

## Feature matrix

See `features.csv`. Must / should / could / skip counts are tallied there. Nintendo IP rows are `skip` with reason `nintendo_ip`.

## Out of scope (cannot or should not be cloned)

- **Nintendo characters and names** (Player must not be named or designed as Mario/Luigi/etc.; enemies/bosses get original names and looks)
- **Nintendo art and trade dress** (sprites, logos, level art, distinctive UI chrome)
- **Nintendo music and SFX** (overworld theme, coin/stomp jingles, voice clips)
- **ROM / binary / board dumps** (no port of the NES executable)
- **Multiplayer** (2P alternating) per user slice
- **Licensed or trademarked product title** in store listing or code identifiers
- Exact level layouts as copyrightable expression: rebuild **original** stages that teach the same mechanics, not byte-identical maps

## Size

Screens 12, flows 5, entities 6. Hard parts: right-only camera + physics feel, tile interaction (bump/break/hidden), shell-kick interactions, castle boss + full 32-stage content load. Size: **L** (mechanics M; full original level pack pushes L).

## Five-line summary

1. **Core loop:** run/jump side-scroll, power ladder, beat the clock, spend lives, clear castle bosses.
2. **Inventory:** 12 screens/states, 5 flows, 6 entities.
3. **Hardest:** jump/run feel, block/item rules, shell combat, authoring ~32 original stages + bosses.
4. **Out of scope:** Nintendo characters/art/music/names, ROM port, multiplayer, copying official maps/audio.
5. **Next step:** `replica-architect` (Godot 4 scenes, physics layers, stage data format) toward macOS export.
