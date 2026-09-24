# Penguin Wars — NEXT SESSION START HERE

Date: 2026-09-23
Status: **END-OF-DAY HANDOFF / AUTHORITATIVE NEXT-SESSION CHECKPOINT**

North star:

**Township feels alive. Expeditions feel like journeys. Combat/builds are replayable enough that players want another run.**

Development rule:

**Build the smallest version that proves the fun. Keep the game playable and visibly improving throughout development. Do not disappear into months of speculative infrastructure.**

---

# 1. CURRENT DIRECTOR STATUS

## Character production — COMPLETE / LOCKED

The following character work is approved and locked:

- Static production penguin
- Rig V2
- Waddle V1.1
- Dash V1.1
- Hit V1
- KO V1
- Revive V1
- Idle V1

Character production stops here unless real gameplay later exposes a specific problem.

Claude owns Blender animation authoring, but Claude is currently idle after completing Idle V1.

Important local production files:

- `art/blender/characters/penguin/production/penguin_wars_concept_c_rig_v2_ko_v1.blend`
- `art/blender/characters/penguin/production/penguin_wars_concept_c_rig_v2_revive_v1.blend`
- `art/blender/characters/penguin/production/penguin_wars_concept_c_rig_v2_idle_v1.blend`

Important review media:

- `art/blender/characters/penguin/previews/penguin_wars_revive_v1_loop_x8.mp4`
- `art/blender/characters/penguin/previews/penguin_wars_idle_v1_loop_x8.mp4`

Known production-art remote checkpoint before KO/Revive/Idle local work:

- branch: `feature/penguin-production-art-v1`
- prior pushed HEAD: `40b658e8bb6137146a9a7221c54cc35c27a88cda`

Do not assume KO/Revive/Idle are already committed remotely. Verify local repo reality before changing anything.

---

## AG character import contract — COMPLETE / LOCKED

Branch:

- `feature/character-animation-import-contract-v1`

Approved HEAD:

- `d1e97edf02879661b56876c4cd18ea3d30221249`

Key locked behavior:

- dual rendered layers: base body + scarf overlay
- body remains untinted
- scarf receives per-player tint
- base/scarf playback stays frame-synchronized
- one-shot presentation duration comes from real animation length / completion
- repeated HIT restarts from frame 0
- DOWNED overrides transients
- arbitrary frame counts are supported
- test fixtures live only under `tests/fixtures/character_animation/`
- production runtime folders contain no fake fixture art
- centralized export contract currently uses 256x256 RGBA, 24 fps, ground anchor (128,216)

Important semantic export QA:

**The base rendered layer must contain NO scarf pixels. The scarf must exist only in the transparent scarf overlay frames.**

Idle-specific runtime rule:

**Export only the 40 displayed Idle frames. Do not export the authoring closure key f41 as a 41st runtime sprite.**

---

## Township geography — APPROVED / LOCKED

Township Blockout V0.2 is approved. Do not make a V0.3 blockout before playtesting it.

Local Blender file:

- `art/blender/environments/township/penguin_wars_township_blockout_v0_2.blend`

Review renders:

- `art/blender/environments/township/renders_v0_2/`

Locked geography:

- Great Hall north / top-center
- large open Town Square in the middle
- Workshop district west
- Fish Market + ice-fishing pond east
- homes southwest
- snow slide west
- departure forecourt south
- Bell + Expedition Lodge + Gate as one departure sequence
- visible future snow-blocked path
- visible unfinished bridge
- visible future build plot
- curved route leading toward Frozen Coast

Current square size:

- about 11 x 9.2 m

Current spatial read:

**Great Hall -> Town Square -> Departure Forecourt -> Bell/Lodge -> Gate -> Expedition**

Do not polish temporary snow rims, placeholder ridges, or blockout buildings before the space is playable.

---

## Field Shop + Larry — DESIGN LOCKED

Design record:

- `docs/design/field_shop_and_larry_v1.md`

Field Shop:

- between-wave run-specific acquisition stop
- Snow is spent on run offers
- V1 target: 3 weapon offers + a paid reroll/refresh
- six-slot WeaponRack remains authoritative
- duplicates occupy real slots and both function
- Field Shop handles Acquire + Commit
- NO direct weapon upgrading
- NO direct merging
- NO maturation at the Field Shop
- maturation remains a separate scarce event

Larry:

- nomadic Field Shop merchant
- recurring unreliable narrator/guide
- introduces himself as: `Larry. With a y.`
- eyepatch
- wooden peg leg visibly tied onto a completely normal healthy orange foot
- treats being stuck in caves for three hours as a life-defining survival ordeal
- useful, dramatic, friendly, self-serious, unreliable in tone
- not an omnipresent narrator

Dialogue direction:

- short console-adventure / Nintendo-style rhythm without copying Nintendo characters, text, UI, or scripts
- 1-2 short sentences per box
- ordinary interactions usually 2-4 boxes
- memorable line beats over paragraphs
- fast advance / skip
- gameplay instructions remain clear and truthful

---

# 2. NEXT CODEX TASK — CHARACTER INTEGRATION V1

Recommended model for this task:

**GPT-5.6 Sol High**

Reason: this is now a real multi-system integration involving Git state, Blender-derived production assets, AG's import contract, Godot runtime presentation, and regression tests.

## Goal

Get the **real locked production penguin animations running in Godot** through the approved CharacterVisual / CharacterPresentationProfile seam, with correct scarf tinting and 1-4 player isolation.

This is a bridge back to gameplay, NOT Character Pipeline Season 2.

## Required sequence

1. **Inspect repo reality first.**
   - Verify branches, worktrees, local changes, and current HEADs.
   - Preserve the older dirty safety branch/stash. Do not clean or delete it.
   - Confirm where KO, Revive, Idle, and Township V0.2 currently exist locally versus remotely.

2. **Start a narrow integration branch.**
   - Suggested name: `feature/character-production-runtime-integration-v1`
   - Base it on the branch/ref that preserves AG's approved V1.1 import contract.
   - Bring in only the locked production-art changes required for real runtime integration.
   - Do not merge to main yet.

3. **Export/build the real character animation frame sets.**
   - Canonical runtime states: idle, move, dash, hit, downed, revive.
   - Map Waddle V1.1 -> `move`.
   - Map KO V1 -> `downed`.
   - Use 24 fps and the centralized contract values unless inspection proves the current contract requires a controlled adjustment.
   - Use real arbitrary frame counts. Do not force fixture counts.
   - Idle: export the 40 displayed frames only, not closure key f41.

4. **Preserve base/scarf separation.**
   - Base frames contain the penguin body and NO visible scarf.
   - Scarf frames contain only the scarf overlay on transparency.
   - Base and scarf frame names/counts must match exactly per state.
   - Scarf tint remains per-player runtime modulation.

5. **Preserve visual/gameplay authority separation.**
   - PenguinPlayer remains gameplay root.
   - CharacterVisual remains presentation root.
   - Visual squash, lean, recoil, collapse, revive, and idle must not move gameplay collision, weapon origins, or world position.
   - Do not restructure gameplay state or physics to make the art fit.

6. **Build/validate the production profile.**
   - Run the approved validator/builder flow from AG V1.1.
   - Production folders must contain only real production frames.
   - Test fixtures must remain under `tests/fixtures/character_animation/`.

7. **Verify real runtime behavior.**
   - IDLE loops seamlessly.
   - MOVE/Waddle loops cleanly while gameplay movement remains authoritative.
   - DASH one-shot completes without truncation.
   - HIT V1 completes at its real duration and repeated hits restart from frame 0.
   - DOWNED reaches and holds the settled KO frame.
   - REVIVE plays through to standing and releases cleanly back to live state.
   - Authoritative DOWNED can interrupt transients immediately.

8. **Verify 1-4 local players.**
   - all players share underlying production SpriteFrames/resources where intended
   - each player's scarf color remains independent
   - body color never receives player tint
   - animation/frame state from one player does not leak into another

9. **Run regression tests.**
   Required minimum:
   - character animation contract test
   - character presentation seam test
   - penguin presentation test
   - foundation test
   - combat feel test
   - renderer smoke test

10. **Produce a real in-game review artifact.**
    - Capture screenshots and/or a short review video showing the production penguin in Godot.
    - Include at least Idle, movement, Hit, Downed, Revive, and multiple scarf colors if practical.

11. **STOP for review.**
    - Do not merge to main.
    - Do not begin Township implementation automatically.
    - Do not build more character pipeline.

---

# 3. DO NOT TOUCH / DO NOT INVENT

During the character integration pass, do NOT:

- redesign locked Blender animations
- create new character animations
- create a separate runtime eye-state architecture just for KO/Revive
- hardcode animation frame counts
- bake one scarf color into the base character
- create generic upgrade/merge UI
- modify Expedition/RoomDefinition architecture
- create CaveJourney
- create CaveDungeonDirector
- create DungeonFloorPlan
- create global current-room state
- create RunPlan
- implement Township NPC simulation
- polish Township environment art
- redesign Township geometry
- merge to main before review

---

# 4. CHARACTER INTEGRATION ACCEPTANCE GATE

Director review should answer YES to all of these:

- Does the real production penguin look correct in Godot?
- Does scarf tinting work independently for 1-4 players?
- Are the locked animation timings visually preserved?
- Does KO look like a real collapse rather than a rotated standing penguin?
- Does Revive remain visibly distinct from reversed KO?
- Does Idle disappear into the character rather than calling attention to itself?
- Do collision/world movement remain stable while visuals animate?
- Are there zero fake fixture frames in production runtime folders?
- Did the integration avoid unnecessary new architecture?
- Is the game ready to move immediately back to playable world/combat progress?

If yes: **APPROVE + LOCK CHARACTER RUNTIME INTEGRATION**.

---

# 5. IMMEDIATELY AFTER CHARACTER INTEGRATION

Next milestone:

**PENGUIN WARS — PLAYABLE TOWNSHIP / FIRST EXPEDITION VERTICAL SLICE**

First playable Township target:

- spawn real production penguin in Township V0.2
- Idle works
- Waddle around the square
- dash and move without environment snagging
- inspect Hall / Workshop / Fish Market spacing through actual play
- physically test the snow slide
- test Fish Market post clearance
- approach Bell / Lodge / Gate
- cross the Gate toward Frozen Coast

Do not demand final Township art before this playtest.

After the space is proven in play, continue toward:

Township
-> Frozen Coast departure
-> handcrafted combat room
-> timed Brotato pressure
-> Snow/reward/build decision
-> connected second room
-> traversal/event/elite
-> maturation moment
-> boss
-> return home

At every step ask:

**If the penguins were circles, would this already feel like Brotato colliding with Zelda?**

---

# 6. SESSION START COMMAND

When opening Codex next session, the intended instruction is:

> Read `docs/handoffs/NEXT_SESSION_START_HERE_2026-09-23.md`, inspect actual repo/worktree state, then execute only Section 2: CHARACTER INTEGRATION V1. Stop after producing the integration report and real in-game review artifact.

End of handoff.