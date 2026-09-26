# Phase A Code-Seam Audit

Status: read-only audit of the current Godot branch `feature/township-locomotion-grounding-v1`.

Purpose: remove implementation guesswork before Monday. This document identifies what already exists, what Phase A can reuse, and the smallest new seams likely required.

## 1. Run / room insertion point

Current authority:
- `scripts/run/expedition.gd`
- `RoomDefinition`
- `RoomSpace.apply()`
- `PartyGate`

Current town exit behavior:
- Township creates a `PartyGate` from a `RoomExit`.
- A town exit currently resolves its target through `RegionDefinition.cave(...)`.
- `enter_cave()` then enters the cave entrance `RoomDefinition`.

### Phase A implication

Do not create a second travel controller.

Smallest safe route:
1. represent the Phase A Frozen Coast as existing region/cave/room data, or extend the region's destination data through the already-authorized Expedition seam;
2. keep `PartyGate` as the transition trigger;
3. load one Phase A combat `RoomDefinition`;
4. attach Frozen Coast-specific visual/collision nodes when that room id is active;
5. keep the closed Ice Arch as local world collision/presentation, not a new travel system.

A Phase A implementation should audit whether the cleanest compatibility move is:
- a new cave/expedition definition whose entrance room is the Frozen Coast Phase A room, or
- a minimal existing-region destination extension.

Do **not** add global current-room state.

## 2. Room space

`RoomDefinition` already supplies:
- rectangular player/enemy bounds
- spawn ring
- supply points
- entry point
- encounter
- exits
- palette

`RoomSpace.apply()` already distributes that data to:
- players
- EncounterDirector
- builder
- loot
- camera
- backdrop

### Phase A implication

The Driftfield can remain one ordinary combat room.

Irregular interior geography should be ordinary world collision under a Frozen Coast room visual node:
- pillars
- boulders
- ribs
- cliffs
- shoreline
- closed arch
- blocked Broken Shelf

Do not try to make `RoomDefinition.bounds` irregular.

## 3. EncounterDirector

Existing `EncounterDirector`:
- owns wave lifecycle
- supports CLEAR_ALL and TIMED pacing
- scales counts by party size
- owns actor spawning
- owns projectiles cleanup
- supports base enemy + charger + ranged scene introduction
- currently chooses seeded points on a perimeter ellipse

Current spawn selection:
- base enemy normally
- charger every third spawn
- ranged every fourth-style cadence from wave 2 onward
- placement uses safest of 12 random points on the spawn ellipse

### Phase A mismatch

Phase A needs authored geography-aware spawn/perch/lane markers.

The current director has no marker-source seam.

### Recommended smallest extension

Add an **optional authored spawn-provider/marker seam** while keeping `EncounterDirector` authoritative.

Example concept:
- room-specific Frozen Coast node exposes arrays/groups of local spawn markers;
- EncounterDirector may be handed those markers by Expedition/composition root;
- if no markers are supplied, preserve existing perimeter behavior exactly.

Do not teach EncounterDirector Frozen Coast names or coordinates.

Skua perches should **not** be general enemy spawn points. Hard-author three Driftfield perch nodes separately.

Tuskbull lane-entry markers may be ordinary authored enemy spawn markers chosen so a readable hard-object lane exists.

## 4. Existing base enemy seam -> Rolly

Existing:
- `EnemyBehavior` direct pursuit already does:
  `enemy.direction_to(target) * enemy.speed`
- `ArenaEnemy` foundation already owns health/contact/knockback/reward behavior.

### Recommended Phase A implementation

Create a Rolly scene inheriting the current `enemy.tscn`.

Reuse:
- ArenaEnemy
- Health
- HitFeedback
- direct-pursuit behavior

Add only what the Rolly needs:
- visual identity
- optional small Rolly-specific behavior for squash tell/lunge if contact-only pursuit does not sell the attack

Do not create a swarm manager.

Loose flocking may be deferred unless playtest shows obvious stacking problems.

## 5. Existing charge seam -> Tuskbull

Existing:
- `ChargeBehavior` states: APPROACH, WINDUP, CHARGE, RECOVER
- target direction locks at WINDUP
- default windup 0.75 s
- default charge speed 360
- default charge time 0.65 s
- default recovery 1.1 s
- high-impulse weapon damage can currently interrupt windup/charge
- `enemy_attack_visual.gd` already reads charge/ranged behavior states for warnings

### Strong reuse

Tuskbull should reuse/adapt `ChargeBehavior`, not invent a second charger architecture.

### New Phase A requirement

ChargeBehavior currently has no environment-impact classification.

Add the smallest optional impact seam needed for Tuskbull:

Hard environment:
- approved pillar/rib collider group or metadata
- charge ends immediately
- enter STUN state or equivalent
- contact damage off during stun
- visible punish window

Soft drift:
- collider/Area2D tag
- reduce charge velocity while overlapping
- never trigger hard stun

Do not implement material physics.

### Behavior compatibility concern

Current `on_damage()` allows high knockback to interrupt a charge. Decide explicitly whether Tuskbull keeps that legacy interrupt.

Recommended Phase A default:
- keep it only if it remains useful and does not undermine the terrain lesson;
- the **main** intended stun remains hard-environment impact.

Human playtest decides later.

## 6. Existing ranged seam -> Skua

Existing `RangedBehavior`:
- POSITION
- WINDUP
- RECOVER
- locks direction at windup
- spawns `EnemySnowball`
- flees when target is close
- approaches when too far
- no pathfinding
- projectile is non-homing after release
- room bounds already travel with projectile

### Reuse

Skua can reuse:
- windup/cooldown model
- committed projectile logic
- DamageEvent path
- room-bounded projectile cleanup

### Phase A change

Skua should not use free ground positioning.

Use exactly three authored Driftfield perches.

Recommended specialized behavior:
- current perch index
- target selection
- windup at perch
- committed lob to target point
- recover
- if threatened, hop to another known perch

No runtime perch discovery.
No navmesh.
No pathfinding.

### Projectile

`EnemySnowball` currently travels a straight direction vector.

Skua concept wants a visible arc and landing point.

Smallest solution:
- a Skua projectile owns start/target/duration;
- visual position follows a 2D interpolation plus cosmetic vertical arc offset;
- damage resolves at committed target point/radius;
- projectile does not retarget.

This can be Skua-specific. Do not replace the existing enemy projectile architecture globally unless a shared base is obviously smaller.

## 7. Weapon runtime today

Current:
- every WeaponRack slot owns an independent `WeaponController`
- cooldown/rack phase lives per controller
- target selection is nearest valid enemy/breakable inside reach
- only two damage patterns exist:
  - SINGLE
  - ARC
- damage is currently instantaneous
- `WeaponVisual` permanently presents held art and animates thrust/sweep from controller state
- damage timing is independent of visual timing

### Phase A implication

The six-slot/dedicated-controller architecture is already correct.

Do not replace WeaponRack.

However, the current `WeaponDefinition.Pattern` enum is too narrow to express:
- Spear line pierce
- Slingshot projectile
- Snowbomb lob + area

Avoid stuffing all three into increasingly complex conditionals inside the old SINGLE/ARC path.

### Recommended smallest extension

Preserve WeaponController as the per-slot cooldown/target authority, but allow a weapon definition/controller to delegate attack execution to a small attack strategy/pattern seam.

Possible bounded shape:
- existing SINGLE and ARC remain unchanged
- add explicit Phase A attack modes or strategy child/resource for:
  - LINE_PIERCE
  - PROJECTILE_SINGLE
  - LOB_AOE

Do not redesign tiers, maturation, classes or rack slots.

## 8. Fish Spear seam

Needed:
- nearest valid target chooses aim direction
- short line segment from player/flipper-side attack origin
- hit each enemy intersecting narrow line once
- medium cadence
- melee DamageKind

Current ARC logic is not a good semantic fit because Spear should be narrow and pierce collinear targets, not sweep a cone.

Smallest implementation:
- line/segment geometry query against current enemy nodes
- sort or simply hit all whose center/hit radius falls within narrow segment corridor and reach
- no physics projectile
- no per-enemy hard-counter multiplier

## 9. Icicle Slingshot seam

Needed:
- per-controller cooldown
- nearest valid target
- visible friendly shard projectile
- long range
- single target
- no default pierce

Current WeaponController can still choose the target.

Smallest new object:
- friendly room-bounded projectile
- carries owner player id / damage event
- swept collision or simple fast segment test
- despawns on first enemy/world hit or room expiry

Reuse concepts from `EnemySnowball` but do not introduce friendly fire.

The projectile trail carries visual identity; the held slingshot can stay visually cheap.

## 10. Snowbomb seam

Needed:
- choose useful cluster in range
- commit to target point
- cosmetic arc
- area hit on arrival
- amber landing cue
- no line-of-sight solver

Recommended targeting:
1. inspect valid enemies in range;
2. for each candidate target position, count nearby enemies inside proposed blast radius;
3. choose highest count, tie-break nearest;
4. launch to that committed point.

This is O(n^2) over the small active enemy set and is acceptable for a Phase A proof.

Do not build spatial partitioning.

Impact:
- query enemies within blast radius
- one DamageEvent per target
- no friendly fire
- no enemy-red telegraph color

## 11. Weapon presentation mismatch with current runtime

Current `WeaponVisual` shows held art continuously whenever player is alive.

Locked new rule:
- penguin remains visually primary
- no permanent weapon chandelier

Phase A should make the smallest presentation change needed for the three starter weapons:
- Spear: stowed/quiet outside target/attack, presents for thrust
- Slingshot: small held/stowed state acceptable, attack/projectile carries most read
- Snowbomb: attack-only or brief held ball, then projectile owns the read

Do not solve all six future weapon families in this pass.

## 12. Data model impact

Current `EncounterDefinition` has:
- enemy_scene
- charger_scene
- ranged_scene
- base_count
- spawn_interval
- wave_count
- boss
- pacing/scaling

For Phase A, the current three-scene slots already map naturally to:
- Rolly
- Tuskbull
- Skua

That means Phase A does **not** need a generic weighted enemy roster yet.

The current fixed introduction cadence may need a local/custom wave schedule if exact teaching waves are required.

Prefer the smallest option:
- either extend EncounterDefinition with an optional explicit Phase A wave composition resource/array,
- or add a tiny room-specific encounter schedule seam.

Do not replace EncounterDirector.

## 13. Exact first implementation order

1. Add Frozen Coast Phase A RoomDefinition + Expedition-compatible destination.
2. Build Frozen Coast visual/collision node and closed arch.
3. Add authored spawn/perch markers.
4. Add Rolly scene and use it as `enemy_scene`.
5. Make Wave 1 playable.
6. Add Spear line-pierce attack.
7. Add Skua scene/behavior + committed lob.
8. Add Slingshot projectile.
9. Add Tuskbull by adapting ChargeBehavior.
10. Add hard-impact + soft-drift classifications.
11. Add Snowbomb.
12. Add explicit four-wave teaching composition if the existing cadence cannot represent it cleanly.
13. 1-4P tests and runtime video.
14. STOP for human playtest.

## 14. Tests to add

Suggested focused tests:
- `frozen_coast_phase_a_route_test.gd`
- `phase_a_enemy_behavior_test.gd`
- `phase_a_weapon_test.gd`
- `phase_a_render_smoke.gd`
- `phase_a_playtest_video.gd`

Assertions should prove behavior/authority, not exact art pixels.

## 15. Risks worth watching

### Highest engineering risk
Tuskbull hard-impact classification and reliable stun.

### Medium
Skua's perch/hop behavior without accidentally creating pathfinding.

### Medium
WeaponController extension becoming a generalized combat rewrite.

### Low-medium
Snowbomb cluster selection and arc presentation.

### Low
Rolly if kept close to current direct-pursuit actor.

## 16. Stop condition

If implementation starts requiring any of these, stop and review:
- new pathfinding/navigation framework
- general terrain system
- generalized projectile architecture rewrite
- Region/Expedition replacement
- WeaponRack rewrite
- global state
- Phase B content

Phase A should fit the game that already exists.
