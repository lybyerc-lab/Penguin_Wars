# Penguin Wars — Production Character Animation Pipeline Contract (v1.2)

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
├── base/          # Remainder of the complete beauty render, transparent at visible scarf pixels
│   ├── idle/
│   ├── move/
│   ├── dash/
│   ├── hit/
│   ├── downed/
│   └── revive/
└── scarf/         # Visible scarf surfaces from the same neutral-scarf beauty render
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

Animation frame counts are variable and not hardcoded. The current production export has Waddle V1.1 at 16 frames, Hit V1 at 7 frames, and Dash V1.1 at 10 frames; fixture counts remain independent.

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

## 7. Production Export Verification

> [!NOTE]
> Character Integration V1 exported the locked source animations into the runtime folders. This checklist records the requirements used for that export:

1. [x] **Rig & Camera**: Ensure orthographic 2.5D camera ($30^\circ-35^\circ$ elevation) with identical framing across all 6 animations.
2. [x] **Canvas**: Uniform $256 \times 256$ pixels, RGBA with transparent background.
3. [x] **Anchor**: Penguin ground contact centered horizontally at $x = 128$, feet contact at $y = 216$.
4. [x] **Visible-surface split**: Render the complete penguin with an in-memory neutral scarf and an object Cryptomatte for `PW_Scarf`, `PW_ScarfKnot`, and `PW_ScarfTail` in the same render. Split the beauty with the visible scarf matte; do not render scarf geometry with the body hidden.
5. [x] **Replacement Protocol**: Replace the target state's complete frame set in both layers; do not leave surplus frames.
6. [x] **File Naming**: `penguin_<state>_###.png` starting at `000`.
7. [x] **Build & Validate**: Run the production profile builder, animation contract test, and scarf export test.
8. [x] **Preview**: Run the real-renderer production character smoke test and inspect 1-4 player scarf tints.

---

## 8. Character Integration V1 export result

The current production profile binds the real locked Blender sources to CharacterVisual in the player scene. The original integration exported the body and neutral white scarf as isolated transparent RGBA layers at 256 x 256, 24 fps, using the existing contract scale and ground anchor. Section 9 records the later visible-surface correction. Source Blender files were copied byte-for-byte from the production-art worktree. Camera lens/shift was normalized in memory for consistent runtime framing; no source rig or pose was saved or redesigned. Godot ignores art/blender via .gdignore because source animation files are not runtime assets.

| Runtime state | Locked source | Base frames | Scarf frames | Playback |
| :--- | :--- | ---: | ---: | :--- |
| idle | Idle V1 | 40 | 40 | loop; authoring closure key f41 excluded |
| move | Waddle V1.1 | 16 | 16 | loop |
| dash | Dash V1.1 | 10 | 10 | one shot |
| hit | Hit V1 | 7 | 7 | one shot |
| downed | KO V1 | 14 | 14 | one shot; hold settled frame |
| revive | Revive V1 | 14 | 14 | one shot |

The production profile and both SpriteFrames resources were built with the approved builder and validated by the animation contract test. Five real-renderer review captures are under docs/character-production-review. Visual acceptance remains subject to director review.

## 9. Visible-surface scarf export correction

The corrected export uses the locked production `.blend` files without saving any source changes. For each frame, `tools/render_visible_scarf.py` renders the **complete** penguin once, with scarf materials copied and neutralized in memory. Blender's object Cryptomatte selects only the visible surfaces of `PW_Scarf`, `PW_ScarfKnot`, and `PW_ScarfTail`. Hidden rear scarf geometry never enters the mask. The existing per-state camera normalization is applied in memory before the combined render.

`tools/split_visible_scarf.py` divides that one beauty render into complementary 256 x 256 base and tintable scarf PNGs. Both layers therefore have the same pose, camera, light, and antialiasing. The base is transparent where visible scarf sits; it is meant to be composited with its required scarf layer. At fractional alpha edges, the split compensates base alpha for standard source-over composition, avoiding dark seams or halos. The neutral recomposite differs from the Blender beauty by at most one 8-bit value per channel over the checked opaque background in all 101 frames.

The committed one-frame Idle proof is under `docs/character-production-review/scarf-visible-v2/proof/`: beauty, Cryptomatte mask, extracted base, extracted scarf, neutral recomposite, and an amplified difference image. `tests/character_scarf_export_test.py` checks that proof and rejects scarf alpha in known visible face, belly, and feet regions of all 40 Idle frames. Rebuilding requires Blender 4.5, Python with Pillow and NumPy, the six locked source files, and the existing Godot resource builder.

The runtime stays a synchronized base `AnimatedSprite2D` plus one independently tinted scarf `AnimatedSprite2D`. Frame counts remain Idle 40, Move 16, Dash 10, Hit 7, Downed 14, and Revive 14 per layer; the Idle closure key is excluded.
