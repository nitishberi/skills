# Bugs

Track gameplay issues here while fixing. Headless scene load is **not** gameplay QA.

## Open (gameplay)

| id | severity | repro | expected | area |
| --- | --- | --- | --- | --- |
| | S1 | | | |

Severity: **S1** crash/blocker, **S2** wrong rules/score/lives, **S3** feel/collision/visual, **S4** polish.

## How we fix

1. Reproduce once with steps (world-stage, input, position if known).
2. Add a row above; pick one bug per commit.
3. Run the matching rows in `test-plan.md` after the fix.
4. In Godot: **Debug → Visible Collision Shapes** while testing hitboxes.
5. Close the row or move to **Closed** with date and commit note.

## Closed / accepted

| id | severity | note |
| --- | --- | --- |
| B08 | S1 | Cap sprite drawn below feet (Art.make_sprite offset); looked off the path; fixed (2026-10-10) |
| B09 | S1 | Stomp used slide normals; landing on enemy killed Cap; position+fall check (2026-10-10) |
| B04 | S2 | Hidden blocks ignored head bumps; fixed in `player.gd` (2026-10-10) |
| B05 | S3 | Spawn Y above ground (304 vs 320); fixed (2026-10-10) |
| B06 | S3 | Spark Star left tint after invuln; reset modulate (2026-10-10) |
| B07 | S3 | Moving platforms did not carry Cap; `get_platform_velocity()` (2026-10-10) |
| B01 | S3 | ~~ColorRect placeholders~~ closed: procedural pixel art via `Art` autoload (2026-10-10) |
| B02 | S3 | macOS .app needs export templates on the user’s Mac (documented) |
| B03 | S4 | No vine bonus; pipe bonus substitutes (skipped in features) |
