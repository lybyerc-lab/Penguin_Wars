# Penguin Wars — Production Character Animation Pipeline Contract (v1.1)

This document specifies the asset layout, dual-layer presentation rig, frame naming, canvas dimensions, pivot/anchor rules, one-shot playback rules, and automated validation for exporting rendered 2D character animations from Blender into Godot.

---

## 1. Directory Layout & Environments

The pipeline establishes a strict separation between source art, runtime production assets, and diagnostic test fixtures:

| Environment | Path | Role & Constraints |
| :--- | :--- | :--- |
| **SOURCE** | `art/blender/characters/penguin/` | 3D rigs, `.blend` animation files, materials, reference cameras. **Strictly untouched by Godot runtime code.** |
| **RUNTIME** | `assets/characters/penguin/production/` | Production destination for final rendered PNG frames. **Contains zero placeholder/fake art.** Subdivided into `base/` and `scarf/`. |
| **TEST FIXTURES** | `tests/fixtures/character_animation/` | Geometric diagnostic placeholder frames used by test suites. Stamped `TEMPORARY TEST FIXTURE`. |

> [!IMPORTANT]
> The runtime production directory `assets/characters/penguin/production/` must never contain fake placeholder frames. All diagnostic fixtures reside in `tests/fixtures/character_animation/`.

---

## 2. Centralized Contract Configuration

Export specifications and runtime alignment constants are centralized in `scripts/data/character_animation_contract.gd`:

| Contract Property | Value | Description |
| :--- | :---: | :--- |
| `CANVAS_SIZE` | `256 x 256` | Uniform square canvas dimension for all frames across all animations. |
| `GROUND_ANCHOR` | `(128, 216)` | Ground contact baseline: horizontal center at $x = 128$, feet contact at $y = 216$. |
| `SOURCE_FPS` | `24.0` | Authored and rendered frame rate. |
| `RUNTIME_SCALE` | `(0.25, 0.25)` | Scale applied to the 256px sprite to yield a 64px character height. |
| `RUNTIME_OFFSET` | `(0.0, -88.0)` | Vertical offset: $-(216 - 128) = -88$ to pin ground contact $(128, 216)$ to actor origin $(0, 0)$. |
| `FILE_PREFIX` | `"penguin"` | Filename prefix for all exported frames. |

All builders, validators, and tests reference `CharacterAnimationContract` as the single source of truth.

---

## 3. Two Synchronized Production Render Layers

To support four local players with independent scarf color identities without duplicating sprite sheets, every animation is rendered into two synchronized layers:

```
assets/characters/penguin/production/
├── base/          # Neutral penguin body (black feathers, white belly, orange feet & beak)
│   ├── idle/
│   ├── move/
│   ├── dash/
│   ├── hit/
│   ├── downed/
│   └── revive/
└── scarf/         # Scarf overlay rendered white / neutral on transparent background
    ├── idle/
    ├── move/
    ├── dash/
    ├── hit/
    ├── downed/
    └── revive/
```

### Layer Synchronization Rules
Both `base/` and `scarf/` layers for any animation state must share identical:
1. **Canvas Size**: Exact same $256 \times 256$ dimensions.
2. **Frame Numbering**: Exact same contiguous 3-digit numbering (`000`, `001`, ...).
3. **Frame Count**: Exactly matching total frame count (every base frame has a counterpart scarf frame).
4. **Animation Timing**: 24.0 FPS.
5. **Ground Anchor**: Exact same ground contact point $(128, 216)$.

### Runtime Presentation Rig
`CharacterVisual` instantiates two synchronized `AnimatedSprite2D` nodes under the visual pivot:
```
CharacterVisual
└── visual pivot
    ├── AnimatedSprite2D (_animated_sprite, base body — modulate = Color.WHITE)
    └── AnimatedSprite2D (_scarf_sprite, scarf overlay — modulate = player.identity.tint)
```
- Base sprite modulate is locked to `Color.WHITE`.
- Scarf overlay modulate is tinted to each player's unique identity color (`p.identity.tint`).
- `flip_h`, `frame`, and `frame_progress` are locked in synchronization every tick.

---

## 4. Canonical States & Playback Contract

| State | Speed (FPS) | Loop Flag | Behavior & Timing Contract |
| :--- | :---: | :---: | :--- |
| `idle` | 24.0 | `true` | Loops continuously while stationary and alive. |
| `move` | 24.0 | `true` | Loops continuously while moving; flipped horizontally on facing. |
| `dash` | 24.0 | `false` | One-shot forward burst. Latches presentation until complete, then returns to `idle`/`move`. |
| `hit` | 24.0 | `false` | One-shot recoil. Duration derived from frame count / FPS (e.g. 6 frames / 24 FPS = 0.25s). **Not** truncated by old constants. Successive hits restart animation from frame 0. |
| `downed` | 24.0 | `false` | One-shot collapse to ice. Plays forward once to completion, then **holds settled final frame indefinitely** while dead without replaying or looping. Authoritative death interrupts any live one-shot immediately. |
| `revive` | 24.0 | `false` | One-shot push-up recovery sequence. Completes forward once before returning visually to live state. |

---

## 5. Arbitrary Frame Count Handling & Replacement Procedure

Animation frame counts are variable and not hardcoded (e.g., approved Waddle V1.1 is 16 frames, Hit is 6 frames, Dash is 4 frames).

### Real Asset Replacement Procedure:
1. **Remove Existing Frame Set**: Delete the prior frame set for that state completely from both `base/<state>/` and `scarf/<state>/` before installing new renders. Never leave surplus frames from a previous revision.
2. **Install New Frames**: Copy the complete new sequential frame sets for `base` and `scarf`.
3. **Verify Numbering**: Ensure numbering starts at `000` with contiguous zero-padded 3-digit integers (`penguin_<state>_000.png`, `001`, ...).
4. **Rebuild SpriteFrames Resources**:
   ```powershell
   godot --headless --script scripts/tools/build_production_profile.gd
   ```
5. **Run Validation & Acceptance Harness**:
   ```powershell
   godot --headless --script tests/character_animation_contract_test.gd
   ```

---

## 6. Automated Pipeline Tools

### Automated Validator (`scripts/tools/character_animation_validator.gd`)
Validates on-disk directories and compiled resources:
- Rejects any paths pointing to `art/blender/`.
- Verifies existence of both `base` and `scarf` layers.
- Verifies exact frame counts and counterpart matching between base and scarf.
- Verifies transparent backgrounds on scarf overlay frames.
- Verifies canvas dimensions ($256 \times 256$).
- Verifies 24.0 FPS and canonical loop flags.
- Verifies `CharacterPresentationProfile` resource bindings.

### Resource Builder (`scripts/tools/build_production_profile.gd`)
Discovers all sequential PNGs in each state directory, builds `SpriteFrames` for both `base` and `scarf`, and saves:
- `resources/characters/penguin_fixture_sprite_frames.tres` (or production)
- `resources/characters/penguin_fixture_scarf_sprite_frames.tres` (or production)
- `resources/characters/penguin_fixture_profile.tres` (or production)

CLI usage:
```powershell
# Build fixture profile from tests/fixtures/character_animation:
godot --headless --script scripts/tools/build_production_profile.gd -- --fixture

# Build production profile from assets/characters/penguin/production:
godot --headless --script scripts/tools/build_production_profile.gd

# Build from custom root:
godot --headless --script scripts/tools/build_production_profile.gd -- --root=res://custom/path
```

---

## 7. Handoff Checklist for Real Sprite Export (Claude & Codex)

> [!NOTE]
> Do NOT begin rendering actual production sprites until directed. When real export begins, follow this checklist:

1. [ ] **Rig & Camera**: Ensure orthographic 2.5D camera ($30^\circ-35^\circ$ elevation) with identical framing across all 6 animations.
2. [ ] **Canvas**: Uniform $256 \times 256$ pixels, RGBA with transparent background.
3. [ ] **Anchor**: Penguin ground contact centered horizontally at $x = 128$, feet contact at $y = 216$.
4. [ ] **Layers Rendered**:
   - Render `base/` pass with penguin body only (scarf hidden/neutral).
   - Render `scarf/` pass with scarf mesh only (body hidden), textured neutral white.
5. [ ] **Replacement Protocol**: Wipe the target state directories before placing new frames.
6. [ ] **File Naming**: `penguin_<state>_###.png` starting at `000`.
7. [ ] **Build & Validate**: Run builder and acceptance test suite.
8. [ ] **Preview**: Run GPU render smoke check (`godot --script tests/render_smoke.gd`).
