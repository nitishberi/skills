# SMB1 mechanics alignment (clean-room)

Evidence: [Super Mario Bros. on Mario Wiki](https://www.mariowiki.com/Super_Mario_Bros.) (2026-10-10 scrape). Pipe Hop matches **rules and feel**, not Nintendo names, art, music, or map data.

## Matched (0.5.0)

| SMB1 rule | Pipe Hop |
| --- | --- |
| Right-only scroll | `right_camera.gd` |
| 400 timer @ ~2.5×; hurry <100 | `SmbTuning` + Music pitch |
| Small / tall / fire ladder | `RunState.form` |
| Hit while powered → small + i-frames + power-down SFX | `player.gd` |
| Small + flower → tall only | `grant_fire` |
| Tall/fire + mushroom block → flower | smart bump in `stage_controller` |
| Star ~10s + star theme; form kept | Zap Star + `Music` `star` |
| Power-up collect = 1000 | grow / fire / star |
| Coin = 200; 100 coins = 1-up | `add_coin` |
| One world item on screen | `_active_world_item` |
| Multi-coin ? block | `MULTI_COIN` Coin Crate |
| Crouch while tall | Cap crouch hitbox |
| Shell wake + kick combo → 1-up | Coilbug |
| Ledge-turn / vertical flyer / fireproof | Cliffbug / Hoverbug / Ashbug |
| Piranha hide when beside pipe; fire KO | Pipe Chomp |
| Cannon silent when adjacent; Bill fireproof | Iron Snout / Pipe Shot |
| Water fauna; no water stomp | Swimfin / Inkjet |
| Lava hopper | Ember Blob |
| Sky Rider follow + eggs + respawn; stop at flag | CloudDropper |
| Toss Twins chase after 100 timer units | `TossTwin` |
| Duke flame W1–5; hammers W6–7; both W8 | `DukeSpikes` |
| Flag height score + fireworks 1/3/6 | `GoalFlag` |
| Spring hold-for-max | Hop Pad |
| Hard Mode beetles + faster + short lifts | Ashbug swap + mover width |
| Exact wiki stage types (W3-2 ground, W8-3 ground, …) | `level_catalog.gd` |
| Continue after game over | C key |
| Death → stage start | product choice (not mid-level checkpoint) |

## Still original / deferred

- **Layouts:** original denser maps (not Nintendo geometry).
- **Names/art/audio:** Mudbit, Coilbug, Rise Melon, Blaze Bud, Zap Star, Extra Melon, etc.
- **Phase C leftovers:** Sky Stem vine, scale lifts, underwater current pull.
- **2-player alternate**, Minus World: out of scope.

## Tuning

Constants in `game/autoload/smb_tuning.gd`.
