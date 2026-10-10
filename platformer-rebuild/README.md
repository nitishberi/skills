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

**8 worlds × 4 stages** (SMB-style types: ground, underground, underwater on W2-2 and W7-2, athletic, castle). Worlds 1–2 use handcrafted layouts; worlds 3–8 are generated from the same type rules with rising difficulty.  
Secret **warp** on 1-1 → World 2; underground warps on select stages. Bonus pipe room, flagpole height score, checkpoints, pause, continue, **Hard Quest** (faster foes). Beat **W8-4** to finish.

## Polish

Original **16px pixel art** (procedural, no Nintendo assets), parallax backgrounds, walk/jump animation, chiptune SFX and stage music. Generated at runtime via the `Art` and `Music` autoloads.

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
