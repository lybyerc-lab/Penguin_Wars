# Township mobile visual cleanup V1

**Status:** all phone-screenshot problem areas are diagnosed. The justified art corrections are staged as candidate layers, and the Godot corrections are listed at the end of section 3. Stopped for review.

**Reserved branch (Codex/director to commit):** `art/township-mobile-cleanup-v1`. I ran no Git and wrote only new files; nothing approved or live was overwritten.

## Paths (all under `art/blender/environments/township/`)

| What | Path |
|---|---|
| Blender file (new) | `penguin_wars_township_visual_v0_1_2_mobile_cleanup.blend` |
| Report | `township_mobile_visual_cleanup_v1_report.md` |
| Before/after sheet | `renders_mobile_cleanup_v1/township_mobile_cleanup_v1_before_after.png` |
| Overview after corrections | `renders_mobile_cleanup_v1/township_mobile_cleanup_v1_overview_after_annotated.png`, plus `…_overview_after_clean.png` |
| Per-area simulation panels | `renders_mobile_cleanup_v1/panels/sim_<area>_before.png` and `…_after.png` |
| Occlusion masks (source of the new layers) | `renders_mobile_cleanup_v1/masks/mask_*.png` |
| Candidate runtime layers (staging only) | `mobile_cleanup_v1_exports/` (10 PNGs + `township_visual_manifest_mobile_cleanup_v1_candidate.json`) |

## 1. How the runtime draws Township (why the bugs happen)

I read this from `feature/mobile-expedition-entry-v1`, the branch the review APK was built from.

- **Layers:** `scripts/town/township_visual_v1.gd` draws one baked plate plus 10 foreground sprites. Each sprite has **one** sort line (`SORT_BASELINES`). A penguin whose feet are north of that line is drawn behind the **entire** sprite.
- **Collision:** `scripts/town/township_v01.gd` still uses the **old v0.2 blockout rectangles**, not the footprints of the approved buildings. The bell has no collision at all.
- **Weapons:** `scripts/combat/weapon_rack.gd:213` sets `controller.z_index = 1`. The z index beats y-sorting, so the weapon draws above every roof and awning even when the penguin is hidden. That is the "floating spear" in screenshots 1, 5 and 6.
- **Verification:** I rebuilt the runtime plate camera in the V0.1.2 file (ortho 56 m, 52° pitch, centred on (0, −2.5)) and it matches `township_background.png` with zero pixel offset. The before/after panels reproduce the runtime draw order in plate space, and they show exactly what the phone showed.

**Coordinate conversion used throughout:** Godot px = (81·X, −80·Y), where X and Y are Blender metres. Plate px = (gx / 1.2656 + 1792, (gy − 200) / 1.5863 + 1008).

## 2. Issues

Root-cause categories: **A** foreground crop · **B** background plate · **C** collision · **D** service pad · **E** camera/runtime · **F** combination.

### Issue 1: Town Hall frontage (screenshot 3)
- **Visible problem:** the penguin at the Elder's pad looks dim or half-gone at the entrance.
- **Root cause: E (+D).** The penguin at the pad (44, −470) is drawn *correctly*: it is 5 cm in front of the portico post line (y −474), nothing overlaps it, and hall collision matches the building to within about 22 px. What hides it is the **service panel**. The hall camera focus (44, −760) puts the pad in the bottom band of the screen, right where the panel draws.
- **Art change:** none needed.
- **Runtime:** raise the hall focus point toward the pad (for example to about (44, −640)), or anchor the service panel away from the player while the hall pad is occupied. Also check that the `great_hall_steps` elevation lift doesn't push the penguin under the panel.

### Issue 2: West / canal side, the slide deck and Workshop (screenshot 6)
- **Visible problem:** at the top of the slide the penguin disappears under the wooden deck. The spear stays visible on top of the deck.
- **Root cause: F = A + C.**
  - **A:** the `slide_foreground` layer put the **raised launch deck** on the slide walls' sort line (390). Everything north of y 390 was hidden by the deck. The same layer also contained a sliver of the Nurse roof.
  - **C:** the space under the deck (x −1115…−946, y −190…−71) and the Workshop's **west forge annex** (x −974…−918, y −373…−290) are walkable. The Workshop collision rectangle is narrower than the building.
- **Art change (made):** `slide_foreground` is re-cut into the following layers:

  | Layer | Sort line |
  |---|---|
  | `slide_deck` | −55 |
  | `slide_bank_1` | 96 |
  | `slide_bank_2` | 240 |
  | `slide_bank_3` | 368 |
  | `slide_bank_4` | 520 |

  The long slide walls are banded so each section sorts at its own depth. The stray Nurse-roof pixels are gone.
- **Runtime:**
  - Block the deck platform with `Rect2(-1115, -190, 169, 119)`.
  - Start the slide Area at the deck's front edge, y ≈ −62. Today it starts at about −150, under the deck.
  - Workshop collision becomes `Rect2(-914, -487, 397, 327)`, plus an annex blocker `Rect2(-970, -369, 52, 75)`.

### Issue 3: Nurse / green-roof hut (screenshot 5)
- **Visible problem:** only the spear shows, lying on the roof; the penguin looks inside or on top of the building.
- **Root cause: F = C + E.**
  - **E (the screenshot itself):** the penguin was walking *behind* the hut, and the roof hiding it there is correct. The spear draws above the roof because of `z_index = 1`.
  - **C:** the Nurse collision is two boxes that leave the south-east corner open (x −603…−522, y 560…620). The approved hut is a solid block with its door at the south-centre, so that notch lets the penguin walk inside the corner wall, where it vanishes behind the whole sprite.
- **Art change:** none. The roof crop is correct.
- **Runtime:**
  - Replace `HomeACollisionNorth` and `HomeACollisionWest` with a single `Rect2(-827, 361, 299, 253)`, matching the approved footprint (x −833…−522, y 355…620).
  - Remove the weapon `z_index`.
  - The pad at (−644, 670) is fine.

### Issue 4: Fisher's Stall (screenshot 2)
- **Visible problem:** the penguin stands on the stall's deck corner, drawn over the post and awning edge.
- **Root cause: F = C + D.**
  - **D:** the pad centre (475, −18) sits **inside** the stall footprint, on the south-west deck corner.
  - **C:** only the counter line has collision (`Rect2(507, -104, 334, 52)`). The deck and the rest of the stall body are walkable. The approved stall is rotated 9° and fills the quad (431, −252), (477, 26), (894, −39), (849, −318).
- **Art change:** none needed. The canopy crop is correct once the penguin can't stand inside the stall.
- **Runtime:**
  - Replace the counter blocker with `ConvexPolygonShape2D` [(437, −250), (479, 20), (888, −43), (846, −312)].
  - Move the Fisher's Stall pad `at` from (475, −18) to **(505, 72)**, just in front of the deck.
  - The sort line −52 can stay.

### Issue 5: General building edges, the Departure Gate and bell (screenshot 1)
- **Visible problem:** the penguin disappears into the bell plinth. It also vanishes under flat snow patches near the gate.
- **Root cause: F = A + C.**
  - **A:** `gate_bell` was one sprite with the gate's sort line (917). The bell, 3 m north of the gate, and several **flat snow patches** (under 0.3 m tall, pure ground) were all drawn over any penguin north of y 917.
  - **C:** the bell has no collision.
- **Art change (made):** `gate_bell` is re-cut into the following layers. Flat snow patches and threshold slabs are removed from the foreground; they stay in the plate, where ground belongs.

  | Layer | Sort line |
  |---|---|
  | `bell` | 598 |
  | `gate` | 900 |
  | `gate_sled` | 754 |
  | `gate_crates` | 782 |
  | `route_signpost` | 1006 |

- **Runtime:** add a bell blocker, a circle at (232, 536) with r 58 (footprint r ≈ 62).

**Screenshot 4** (The Hollow Shelf cave room) is not Township. There was nothing to diagnose, and it is out of scope.

## 3. Exact changes

### Blender objects and layers (V0.1.2)
- **Approved Township geometry, materials, lights and cameras:** unchanged from V0.1.1. Temporary holdout and hide states used for mask renders were restored; I verified no holdout flags remain.
- **Added: `TSV_Cam_RuntimePlate`**, a camera in `REVIEW_Cameras` that reproduces the runtime plate. The active scene camera stays `TSV_Cam_Gameplay`.
- **Added: collection `MOBILE_CLEANUP_V1_not_for_export`**, excluded from the view layer so normal renders are unchanged. It contains:
  - `MC_MaskSources_islands`: 20 mask-only island copies, `MC_TSV_Gate_Snow_isl00–12`, `MC_TSV_Bell_Snow_isl00–02` and `MC_TSV_Slide_Banks_isl00–03`.
  - `MC_RuntimeGuides`:
    - 10 sort-line empties, `MC_SortBaseline_*`;
    - 6 recommended-collision outlines, `MC_Collision_Bell / WorkshopMain / WorkshopWestAnnex / SlideDeckPlatform / NurseHut / FishersStall`;
    - 2 pad markers, `MC_ServicePad_FishersStall_OLD / NEW`.
- **Mask renders:** only the objects of each new layer were rendered, with everything else as holdout, from `TSV_Cam_RuntimePlate`. Each candidate PNG is the shipped plate × that mask, so it is pixel-identical to the plate.

### Runtime layers that must be regenerated or replaced

| Live layer (unchanged; not overwritten) | Candidate replacements in `mobile_cleanup_v1_exports/` |
|---|---|
| `township_gate_bell.png` | `township_bell.png`, `township_gate.png`, `township_gate_sled.png`, `township_gate_crates.png`, `township_route_signpost.png` |
| `township_slide_foreground.png` | `township_slide_deck.png`, `township_slide_bank_1…4.png` |

The candidate manifest JSON gives each file's crop, in the same pixel space and padding convention as `township_visual_manifest.json`, and its sort line.

**Unchanged:** `township_background.png` and the other 8 layers:
- `great_hall`
- `workshop`
- `nurse_hut`
- `home_b`
- `fishers_stall`
- `fish_shed`
- `net_shed`
- `expedition_lodge`

### Godot and runtime corrections still needed (not done; no code touched)
1. **Weapon draw order:** `scripts/combat/weapon_rack.gd:213`, remove `controller.z_index = 1` so weapons y-sort with their owner. This fixes the floating spear everywhere.
2. **`TownshipVisualV1`:**
   - replace the `gate_bell` and `slide_foreground` entries with the 10 new layers and their sort lines;
   - merge the candidate manifest entries into `township_visual_manifest.json`;
   - copy the PNGs into `assets/environments/township_visual_v1/`.
3. **Collision in `township_v01.gd`:**
   - bell circle (232, 536) r 58;
   - Nurse single `Rect2(-827, 361, 299, 253)`;
   - Workshop `Rect2(-914, -487, 397, 327)` plus annex `Rect2(-970, -369, 52, 75)`;
   - slide deck `Rect2(-1115, -190, 169, 119)`;
   - Fisher's Stall convex polygon (above).
4. **Slide Area:** move its top edge south to about y −62, clear of the deck. Verify in the editor.
5. **Fisher's Stall pad:** `town_hub.gd`, change `at` (475, −18) to (505, 72).
6. **Town Hall panel versus pad:** change the camera focus or the panel anchor, as in issue 1.
7. **Optional:** a player silhouette when a penguin is legitimately behind a building (roofs hide the whole penguin). This is a readability nicety, not required.

## 4. Intentionally left unchanged
- **Township geography, buildings, entrances, square, pond, slide route, camera and penguin scale:** untouched. There were no new props, routes or decorations.
- **Great Hall layer:** no split. The screenshot problem is the UI panel, not art. The hall collision is about 22 px short of the walls; that is harmless and not in scope.
- **Other small collision gaps:** the Nurse and Workshop gaps of about 14 px are folded into the rectangles above. The remaining minor lamp-post depth cases were left alone.
- **Fisher's Stall and Nurse art:** their crops are correct; their fixes are collision and pad only.
- **Live runtime PNGs and manifest:** not overwritten; the candidates are staged separately.
