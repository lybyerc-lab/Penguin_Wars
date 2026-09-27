# Frozen Coast Phase A V0.1: package notes

**Status:** production art approved for Godot integration. This package is packaging only; no art, data, Godot, Git or Township files were changed to make it.

## Contents
- `penguin_wars_frozen_coast_phase_a_runtime_v0_1.zip`: everything the proven Phase A runtime needs. These are the complete contents of `phase_a_v0_1_exports/`, with the filenames unchanged, minus the `_work/` scratch folder.
- `penguin_wars_frozen_coast_phase_a_source_v0_1.zip`: a source and archive copy for future re-exports. It contains:
  - the production `.blend`;
  - the production report;
  - review renders 01–08;
  - all 29 layer masks;
  - `phase_a_v0_1_exports/`.

  It leaves out raw renders, work-in-progress renders, `_work/` and `.blend1` backups; all of these can be regenerated.

## About the masks in the source ZIP
- **What changed:** the masks are stored as *alpha-exact* copies. The alpha channel is bit-for-bit identical to the originals, and RGB is cleared to 0.
- **Why:** the full-colour originals are about 4 MB each (116 MB in total). The alpha-exact set is 1.2 MB, which keeps the archive small enough to transfer.
- **Nothing is lost:** `phase_a_cut_layers.py` reads only the alpha channel. Re-cutting from these masks was verified to reproduce all 29 layer PNGs pixel-identically, with an identical manifest.
- **Originals:** the full-colour masks are unchanged in `renders_phase_a_v0_1/masks/` on the art machine, and `phase_a_export_masks.py` regenerates them from the `.blend`.

## Locked integration decisions (approved)
1. **Route:** the Phase A route stays **Township Gate → Pass → Driftfield → closed Ice Arch**.
2. **Out of scope:** no Broken Shelf, Hole Eel, Wreck Yard, Old Berg, Ancient Funnel, cave, boss or later-region content.
3. **Foreground layers:** keep the 29-object foreground layer approach. Each layer has its own sort baseline, taken from the manifest.
4. **Snow drifts:** they stay baked into the background plate.
5. **Whale ribs:** they stay split into 12 layers for correct sorting.
6. **Rib collision:** use two continuous rib-wall collision chains, `rib_wall_south` and `rib_wall_north`, not 12 individual rib colliders.
7. **Wedge fill:** `rib_south_wedge_fill` is a blocker. It is **not** a Tuskbull stun object.
8. **Hard Tuskbull impact objects:**
   - pillars A, B, D, E;
   - boulders A, B, C;
   - the skull;
   - both rib walls;
   - appropriate world boundaries.
9. **Soft terrain:** the eight snow-drift zones may slow a Tuskbull charge but never stop it.
10. **Skua perches:** the coordinates stay in `frozen_coast_phase_a_guides_v0_1.json`. Runtime perch behaviour will be decided after the first integrated playtest.
11. **Rim opacity:** the four `rim_*` foreground layers are approved at **45% opacity** (`modulate.a = 0.45`) in Godot, for player readability.

## Correction to the production report
The report's warning about a forced `z_index = 1` in `weapon_rack.gd` is **historical information only**. The current proven Phase A runtime no longer contains that assignment. **No change is needed; do not modify weapon code.**

## Key runtime numbers
| Item | Value |
|---|---|
| Plate | `frozen_coast_phase_a_background.png`, 3584 × 2816 |
| `background_centre` (Godot px) | (−324, −1273.6) |
| `sprite_scale` | (1.265625, 1.586272619350546) |
| Godot px from Blender metres | (81·x, −80·y) |
| Spawn | (−1681, 800) |
| Township return trigger | y = 920 |
| Phase A end (closed arch) | y = −2800 |
