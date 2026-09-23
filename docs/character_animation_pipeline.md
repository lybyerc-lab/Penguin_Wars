# Penguin Wars — Production Character Animation Pipeline Contract

This document specifies the asset layout, naming, canvas, pivot, playback, and validation contract for exporting rendered 2D character animations from Blender into Godot.

---

## 1. Source Art vs. Runtime Assets

| Asset Type | Location | Notes |
| :--- | :--- | :--- |
| **Source Art (Blender)** | `art/blender/characters/penguin/` | Rigs, reference images, `.blend` files, work-in-progress render previews. Strictly read-only for Godot runtime code. |
| **Runtime Assets (Godot)** | `assets/characters/penguin/production/` | Production-ready transparent PNG frames consumed directly by Godot's `SpriteFrames`. |

> [!IMPORTANT]
> Never place runtime-ready sprite frames inside `art/blender/`. Godot scenes and resources reference assets exclusively from `assets/characters/penguin/production/`.

---

## 2. Canonical States & Directory Structure

Every character animation set consists of exactly six canonical states:

```
assets/characters/penguin/production/
├── idle/      # Gentle breathing loop
├── move/      # Waddle walk cycle loop
├── dash/      # Aerodynamic forward burst lean
├── hit/       # Recoil flinch reaction
├── downed/    # Collapse to belly on ice + held KO pose
└── revive/    # Push-up recovery get-up sequence
```

---

## 3. Frame Naming Convention

Frames must follow a strict, deterministic, 3-digit zero-padded sequential naming format:

$$\text{penguin\_}\langle\text{state}\rangle\text{\_}\langle\text{frame:03d}\rangle\text{.png}$$

Examples:
- `idle/`: `penguin_idle_000.png`, `penguin_idle_001.png`, `penguin_idle_002.png`, `penguin_idle_003.png`
- `move/`: `penguin_move_000.png`, `penguin_move_001.png`, ..., `penguin_move_007.png`
- `dash/`: `penguin_dash_000.png`, `penguin_dash_001.png`, ..., `penguin_dash_003.png`
- `hit/`: `penguin_hit_000.png`, `penguin_hit_001.png`, `penguin_hit_002.png`
- `downed/`: `penguin_downed_000.png`, `penguin_downed_001.png`, ..., `penguin_downed_005.png`
- `revive/`: `penguin_revive_000.png`, `penguin_revive_001.png`, ..., `penguin_revive_005.png`

**Rules**:
- Start indexing at `000`.
- Numbering must be strictly contiguous without gaps or duplicate numbers.
- Do NOT encode version numbers in runtime filenames (e.g. no `_v1` or `_v2`). Versioning belongs in source art Git history.

---

## 4. Canvas Dimensions & Ground Anchor Rule

- **Canvas Size**: Uniform **$256 \times 256$ pixels** across all six states and all frames.
- **Anchor / Pivot**:
  - Horizontal Center: $x = 128$ px.
  - Ground Plane Baseline: $y = 216$ px (where the penguin's feet make ground contact when standing).
- **No Baked Translation**: The character's gameplay origin stays fixed at the anchor. Visual limbs, flippers, and body may squash, stretch, and lean around the anchor, but the character must not walk out of the frame. World translation is controlled 100% by Godot's `CharacterBody2D`.
- **No Canvas Drifting**: All rendered frames must share an identical camera position and orthographic bounds in Blender.

---

## 5. Frame Rate & Playback Contract

All animations are authored and rendered at **24.0 FPS**.

| Animation State | Speed (FPS) | Loop Flag | Expected Behavior |
| :--- | :---: | :---: | :--- |
| `idle` | 24.0 | `true` | Loops continuously while alive and stationary. |
| `move` | 24.0 | `true` | Loops continuously while moving; flipped horizontally on facing. |
| `dash` | 24.0 | `false` | Plays forward lean burst once; duration tracked by `DashController`. |
| `hit` | 24.0 | `false` | Plays flinch recoil once; duration tracked by `_hit_timer`. |
| `downed` | 24.0 | `false` | Plays collapse once, then **holds the final settled KO frame** while dead. |
| `revive` | 24.0 | `false` | Plays push-up once, then seamlessly recovers to `idle` or `move`. |

---

## 6. Downed / KO End-Frame Hold Behavior

When a player dies:
1. `CharacterVisual` transitions to `DOWNED` and triggers `downed` animation from frame 0.
2. The collapse sequence plays forward once.
3. Upon reaching the final frame (e.g. `penguin_downed_005.png`), `AnimatedSprite2D` halts automatically (`loop = false`).
4. `CharacterVisual` maintains the settled final frame as long as the player remains in `DOWNED`. It does **not** re-call `.play()`, preventing any re-looping or stuttering.
5. When `Health.revived` emits, `CharacterVisual` transitions to `REVIVE`, playing the push-up sequence from frame 0 before returning to `IDLE`.

---

## 7. Resource Construction & Profile Binding

### `SpriteFrames` Resource
Configured at `res://resources/characters/penguin_production_sprite_frames.tres`:
- Contains all 6 animations (`idle`, `move`, `dash`, `hit`, `downed`, `revive`).
- Each animation speed set to `24.0`.
- Loop flags set according to Section 5.

### `CharacterPresentationProfile` Resource
Configured at `res://resources/characters/penguin_production_profile.tres`:
```gdscript
profile_name = "Penguin Production Rig v2"
sprite_frames = preload("res://resources/characters/penguin_production_sprite_frames.tres")
base_scale = Vector2(0.25, 0.25) # 256px * 0.25 = 64px character height
offset = Vector2(0, -88)         # Aligns ground baseline (y=216) with Godot origin (0, 0)
flip_h_with_facing = true
anim_idle = &"idle"
anim_move = &"move"
anim_dash = &"dash"
anim_hit = &"hit"
anim_downed = &"downed"
anim_revive = &"revive"
```

---

## 8. Validation Tool

A dedicated validator tool is available at `scripts/tools/character_animation_validator.gd`.

Run validation headlessly:
```powershell
godot --headless --script tests/character_animation_contract_test.gd
```

The validator checks:
1. Presence of all 6 canonical state directories and animations.
2. No unexpected files in runtime folders.
3. Strict `penguin_<state>_###.png` naming starting at `000` with no gaps or duplicates.
4. Consistent $256 \times 256$ dimensions across all frames and states.
5. Exact 24.0 FPS configuration.
6. Correct loop flags (`idle`/`move` looping; `dash`/`hit`/`downed`/`revive` non-looping).
7. Valid profile animation mappings.

---

## 9. Handoff Checklist for Real Sprite Export (Claude & Codex)

When exporting real Blender renders into Godot:
1. [ ] Render transparent background PNGs with anti-aliasing.
2. [ ] Render from orthographic 2.5D camera ($30^\circ-35^\circ$ elevation).
3. [ ] Crop/render to uniform $256 \times 256$ square canvas.
4. [ ] Keep ground contact anchor centered horizontally ($x = 128$) and at ground line ($y = 216$).
5. [ ] Save into `assets/characters/penguin/production/<state>/` using `penguin_<state>_###.png`.
6. [ ] Re-run the automated validator to confirm 0 errors:
   ```powershell
   godot --headless --script tests/character_animation_contract_test.gd
   ```
7. [ ] Run real GPU smoke preview:
   ```powershell
   godot --script tests/render_smoke.gd
   ```
