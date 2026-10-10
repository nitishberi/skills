# SMB1 mechanics alignment (clean-room)

Evidence: [Super Mario Bros. on Mario Wiki](https://www.mariowiki.com/Super_Mario_Bros.) gameplay section (2026-10-10). Pipe Hop matches **rules and feel**, not Nintendo names, art, music, or map data.

## Matched

| SMB1 rule | Pipe Hop |
| --- | --- |
| Right-only scroll | `right_camera.gd`, `RunState.max_camera_x` |
| 400 timer units, faster than real time | `SmbTuning.STAGE_TIME_DISPLAY`, `TIMER_UNITS_PER_SECOND` |
| Hurry when timer low | Music pitch up below 100 units |
| Small / tall / fire ladder | `RunState.form`, blocks, pickups |
| Hit while powered → small + i-frames | `player.gd` (fire and tall → small, SMB1) |
| Star invuln ~10s contact KO | `STAR_SECONDS`, invuln stomp path |
| Pit, timeout, small hit = life lost | stage + `RunState` |
| 100 coins = 1-up | `add_coin` |
| Continue after game over (world) | `apply_continue` + C key |
| Hard second quest faster foes | `hard_quest`, `HARD_ENEMY_SPEED_MUL` |
| Underwater: no stomp KOs | `in_water` branch in `player.gd` |
| Max 2 fireballs | `MAX_FIREBALLS` |
| Flagpole height score | `GoalFlag` + `SmbTuning.flagpole_bonus` |
| Mid-level checkpoint respawn | `RunState.checkpoint_*` |
| Castle axe / fire on boss | `AxeGoal`, ember hits on Duke |
| Warp, pipe bonus | warp zone, bonus room |

## Still original / abbreviated

- **2 worlds × 4 stages** (not 8×4); layouts are original teaching beats, not official maps.
- **Branding**: Cap, Browncap, Duke Spikes, Pipe Hop audio/art.
- **2-player alternate**, vine beanstalk, exact NES frame data: not ported.

## Tuning knob

Constants live in `game/autoload/smb_tuning.gd` (autoload `SmbTuning`). Adjust there, then re-run `test-plan.md` F01–F05.
