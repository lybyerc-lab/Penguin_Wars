# SmartShape2D Frozen Coast — evaluation spike

**Experiment, not adopted.** Evaluates SmartShape2D 3.3.2
(`SirRamEsq/SmartShape2D` @ `9617190`, installed unmodified in
`addons/rmsmartshape`) as terrain dressing for handcrafted rooms. Nothing here is
wired into a cave or reachable from `Expedition`.

## The one rule this spike holds

`frozen_coast_room.tres` (a plain `RoomDefinition`) owns the geography:
bounds, entry, exits, spawn ring, supply points. `frozen_coast.gd` wires it
exactly like `TestArena`, through `RunSession` and `RoomSpace.apply()`.
Everything under `Terrain` is SmartShape dressing and stores no gameplay data.
`Terrain/ShelfCollision` holds SmartShape's editor-baked coastline collision and
ships **inert** (no layer, no mask); the verifier switches it on only to
measure it.

## Files

| File | Purpose |
| --- | --- |
| `frozen_coast.tscn` / `.gd` | The prototype room and its composition root |
| `frozen_coast_room.tres` | Authoritative room data |
| `terrain/` | Placeholder textures and SmartShape materials |
| `build_frozen_coast.gd` | Rebuilds the scene from a point layout (stands in for hand authoring) |
| `generate_textures.gd` | Regenerates the placeholder textures |
| `verify_frozen_coast.gd` | Authority checks and collision measurements (headless) |
| `capture_frozen_coast.gd` | Runtime, collision-overlay and comparison captures |
| `measure_frozen_coast.gd` | Draw calls, load time and memory vs the rectangular arena |
| `probe_without_addon.gd` | What survives if the addon folder is deleted |
| `editor_session/`, `editor_probe/` | Real-editor harnesses; inert unless launched with their flag, never committed as enabled |

## Running

```
godot --headless --path . --script res://experiments/smartshape_frozen_coast/verify_frozen_coast.gd
xvfb-run -a godot --path . --display-driver x11 --rendering-driver opengl3 \
  --script res://experiments/smartshape_frozen_coast/capture_frozen_coast.gd
xvfb-run -a godot --path . --display-driver x11 --rendering-driver opengl3 \
  --script res://experiments/smartshape_frozen_coast/measure_frozen_coast.gd
```

The editor session needs its plugin temporarily added to `[editor_plugins]`,
then `godot --path . --editor -- --ss2d-eval-session`.

## Removing the spike

Delete `experiments/smartshape_frozen_coast/` and `addons/rmsmartshape/`, then
drop the `[addons]` and `[editor_plugins]` sections from `project.godot`.
Nothing else in the project references SmartShape. Delete the folder and the
addon together: `frozen_coast.tscn` will not load without the addon.
