# SolidCraft Agent Lessons (seed)

Seeded from the modelling history session (2026-10-28 through 2026-10-30).
Status for each entry below is `seed` until folded or superseded.

## L001 - Units after new_design
- **Status:** seed
- **Rule:** Always run `document.units {units:"mm"}` right after `new_design`. Designs can open in inches.
- **Why:** Drawing values are inches; model units are mm (1 in = 25.4 mm).

## L002 - Thickness matches the labelled feature
- **Status:** seed
- **Rule:** Match each thickness callout to the feature it labels. Do not reverse rib vs end thicknesses.
- **Correction pattern:** On the -9 link, the rib is 1.00 and the eye ends are .500. Rebuild as a 1.00 blank with ends pocketed to .500 when thicknesses were swapped.

## L003 - Use every number in a compound callout
- **Status:** seed
- **Rule:** Use every number in a compound callout (width, angle, depth). Do not invent geometry from one number alone.
- **Correction pattern (C32057-51 bevel):** Callout `.50 × 60°` means .50 wide at 60°, depth = .50 × tan(60°) ≈ .866, leaving a flat of thickness - depth on a 1.0 plate (.134). A full-thickness 60° cut yields width ≈ 1.0 / tan(60°) ≈ .577 and contradicts the .50 callout.

## L004 - Model only the requested dash
- **Status:** seed
- **Rule:** On multi-part sheets, model only the dash or part number the user named. Ignore sibling dashes unless asked.

## L005 - Name and save with the user's part number
- **Status:** seed
- **Rule:** Name the design and save file using the user's part number (for example `C32057-51.sc`).

## L006 - Verify mirrored features on both sides
- **Status:** seed
- **Rule:** Verify mirrored features from the built model on both sides (widths, angles, hole columns). Sketch origin typos on one side can leave asymmetric geometry.

## L007 - Permanent save folder
- **Status:** seed
- **Rule:** SolidCraft's allowed folder can change when its MCP server restarts. Save to the configured permanent models folder, not only the session temp directory.

## Kernel workarounds (reference)
- Fillet "blend larger than neighbouring faces": larger fillets first; reduce the one that cannot fit; or sketch a profile body, intersect, combine.
- Join failed on coincident side faces: oversized blank plus pocket cuts.
- Trim cut skipped on coincident arcs: oversized intersect profile and a separate body.
- Intersect changed only the first target: run again for each target.
- `solid.thread` with inch UNC strings: ISO metric only; leave inch threads unmodelled and use tap-drill diameters.
