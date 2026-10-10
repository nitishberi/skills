# Pipe Hop

Personal-use side-scroll platformer. Classic run-and-jump feel with original names, colors, and audio (not for sale; not Nintendo IP).

## Play

```bash
godot --path game
```

Godot **4.3+**. On macOS: Import `game/project.godot` → Play.

## Controls

| Action | Keys |
| --- | --- |
| Move | A / D or arrows |
| Jump / swim stroke | Space or Z |
| Run / shoot ember | Shift or X |
| Enter pipe / swim down | S or Down |
| Pause | Esc or P |
| Start | Enter or Space |
| Hard Quest (title, after a clear) | H |
| Continue (game over) | C |

## Content

**World 1:** overworld → under → athletic (springs, movers, Spark Star, cloud dropper) → castle (fire-bars, lava, Duke Spikes).  
**World 2:** underwater → pipes/plants → sky drops → harder castle.  
Secret **warp** on 1-1 near the stairs → World 2. Hidden blocks, 1-Up, bonus pipe room, stage-clear tally, pause, continue, Hard Quest.

## Cast (ours)

Cap, Browncap, Shellbug, Big Berry, Ember Bloom, Spark Star, One-Up berry, Duke Spikes, HazardPlant, CloudDropper.

## Exports

Presets live in `game/export_presets.cfg` (Godot 4.3 export templates required).

| Target | Command / UI | Output |
| --- | --- | --- |
| macOS | Project → Export → **macOS**, or `godot --headless --path game --export-release "macOS" ../build/PipeHop.app` | `build/PipeHop.app`, zip as `build/PipeHop-macOS.zip` |
| Linux x86_64 | Project → Export → **Linux**, or `godot --headless --path game --export-release "Linux" ../build/PipeHop.x86_64` | `build/PipeHop.x86_64` + `build/PipeHop.pck` |

On a Mac: unzip `PipeHop-macOS.zip`, open `PipeHop.app` (unsigned; right-click → Open if Gatekeeper blocks). On Linux: `./PipeHop.x86_64` next to the `.pck`.

## Replica notes

Pipeline artifacts: `replica/`. Clean-room mechanics only; Nintendo characters/art/music/names stay skipped.
