# Monday Codex Handoff — Penguin Wars Phase A

**Recommended model: GPT-5.6 Sol High**

**Reason:** this is the first playable implementation of a new expedition region plus three enemies and three weapon behaviors. It crosses room/travel, encounter, enemy-behavior, weapon-runtime and co-op seams. Keep the scope narrow and stop after the Driftfield proof.

## Starting point

Use:
- base branch: `feature/township-locomotion-grounding-v1`
- approved grounding HEAD: `db9a7e8a660abe5273bed5f84f1e4f46126bf31a`

Read first:
- `docs/production/phase-a-build-pack-v1.md`
- `docs/production/phase-a-code-seam-audit.md`
- `docs/automation/NIGHT_SHIFT_QUEUE.md`

Do not merge main.

## Task

Build only the first playable Frozen Coast slice:

**Township Gate -> Pass -> Driftfield**

Enemies:
- Rolly
- Skua Slinger
- Tuskbull

Weapons:
- Fish Spear
- Icicle Slingshot
- Snowbomb

The build ends at the closed crevasse/Ice Arch. Broken Shelf and all Phase B/C content remain inaccessible.

## Required design locks

- Existing Expedition / PartyGate / RoomDefinition / EncounterDefinition / RunSession authority remains intact.
- Existing 1-4 local co-op remains intact.
- Existing WeaponRack six-slot model remains intact.
- No navmesh/pathfinding framework.
- No general terrain engine.
- No full combat architecture rewrite.
- No Phase B content.
- Tuskbull:
  - hard pillar/rib impact -> crash + stun
  - barchan drift -> slow charge only, no stun
- Skua uses exactly 3 authored Driftfield perches in Phase A. No runtime perch discovery.
- Snowbomb uses simple cluster targeting, no LOS solver.
- Tuskbull lane is translucent and must not hide players.
- Rolly gets no ground telegraph.
- Snowbomb landing cue is amber, never enemy red.

## Build order

1. Frozen Coast Phase A RoomDefinition / route insertion.
2. Pass + Driftfield world visual/collision.
3. closed Ice Arch / blocked Broken Shelf.
4. authored spawn/perch/lane markers.
5. Rolly.
6. Fish Spear.
7. Wave 1.
8. Skua.
9. Icicle Slingshot.
10. Wave 2.
11. Tuskbull hard/soft environment interaction.
12. Snowbomb.
13. Waves 3-4.
14. 1-4P validation.
15. runtime video/screenshots.
16. STOP.

Do not stack the next role on top if the current layer is obviously broken.

## Starting encounter sequence

Initial playtest numbers only.

### Wave 1
1P:
- 6 Rollies

Each extra player:
- +2 Rollies

### Wave 2
1P:
- 6 Rollies
- 1 Skua

Extra players:
- +2 Rollies each
- second Skua only at 3-4 players

### Wave 3
1P:
- 8 Rollies
- 1 Tuskbull

Extra players:
- +2 Rollies each

### Wave 4
1P:
- 8 Rollies
- 1 Skua
- 1 Tuskbull

Extra players:
- +2 Rollies each
- second Skua only at 3-4 players

These values are not balance locks.

## Required tests

Add focused tests for:
- Township PartyGate -> Frozen Coast Phase A
- closed arch / no Broken Shelf access
- Rolly pursue + squash/lunge tell
- Skua authored perch use
- Skua target-point lock before throw
- Skua projectile non-homing after commit
- Tuskbull lane lock
- hard impact -> stun
- drift overlap -> slowdown/no stun
- miss -> recovery
- Fish Spear short line pierce
- Icicle Slingshot single-target projectile
- Snowbomb committed arc + area hit
- Snowbomb amber cue
- 1-4P scaling and max 2 Skuas
- no regression to Township, grounding, character/scarf, WeaponRack, economy/Snow, doorway/travel, mobile

## Review artifacts

Provide:
- Town -> Pass arrival screenshot
- Driftfield clean screenshot
- Wave 1 screenshot
- Skua telegraph screenshot
- Tuskbull lane + hard-impact screenshot
- Snowbomb cluster screenshot
- four-player mixed-wave screenshot
- one short runtime video showing:
  Town exit -> Pass -> Driftfield -> Wave 1 -> Skua -> Tuskbull crash -> mixed wave

## Report

Return:
1. branch + HEAD
2. worktree
3. exact files changed
4. route implementation
5. spawn/perch marker implementation
6. Rolly behavior
7. Skua behavior/projectile
8. Tuskbull hard/soft interaction
9. three weapon implementations
10. wave schedule implementation
11. 1-4P behavior
12. tests
13. review artifacts
14. anything that feels awkward
15. any place implementation wanted to become a larger framework

## Stop condition

STOP after Phase A is playable and reviewable.

Do not:
- build Hole Eel
- build Wreck Yard
- build floe traversal
- build Lid Boomerang
- build Sentry
- build Tern
- build Old Berg
- build cave gameplay
- build Larry/Field Shop
- build maturation
- merge main

The only question this branch must answer is:

> Is the first Frozen Coast combat ecosystem fun?
