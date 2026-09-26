# Penguin Wars - Phase A Build Pack V1

Status: implementation-ready design pack for the first playable Frozen Coast slice.

Branch context: this planning branch is based on `feature/township-locomotion-grounding-v1`. It does not authorize a merge to `main`.

## 1. Goal

Build the smallest playable slice that proves whether Penguin Wars combat is fun in an adventure space:

**Township Gate -> Frozen Coast Pass -> Driftfield**

Phase A ends at the crevasse edge. The Ice Arch is visibly closed. Broken Shelf, Wreck Yard, Hole Eel, Old Berg, cave gameplay, Larry, Field Shop, maturation, boss content and Phase B/C weapons remain out of scope.

### Phase A content

Enemies:
- Rolly
- Skua Slinger
- Tuskbull

Weapons:
- Fish Spear
- Icicle Slingshot
- Snowbomb

Primary playtest question:

> Is Rolly + Skua + Tuskbull, fought in the Driftfield with Spear + Slingshot + Snowbomb, fun enough that the player wants another wave/run?

## 2. Locks and architecture guardrails

Keep the existing project contracts intact.

- `Expedition` remains the travel authority.
- `PartyGate` remains the whole-living-party transition rule.
- `RoomDefinition` owns geography/bounds data only.
- `EncounterDefinition` owns combat/wave data only.
- `RunSession` remains shared runtime wiring.
- No global current-room state.
- No new dungeon director, run planner, terrain engine, pathfinding framework or general environment-import framework.
- Shared Resource definitions remain immutable at runtime.
- `EncounterDirector` remains the combat/wave lifecycle authority.
- `ArenaEnemy`/existing EnemyBehavior seams remain the shared enemy foundation.
- `Health.take_damage(DamageEvent)` remains the damage seam.
- Existing 1-4 player identity, wallets, WeaponRack, Snow, dash, downed, scarf, character visual and camera systems remain authoritative.
- The approved production penguin is not modified by Phase A.

## 3. Frozen Coast Phase A geography

### 3.1 Visual identity

Frozen Coast should contrast Township:

Township:
- warm
- enclosed
- inhabited
- organized

Frozen Coast:
- blue-white
- open
- wind-carved
- exposed
- dangerous
- beautiful

Phase A visual ingredients:
- slate cliff lips
- wind-carved snow
- crescent/barchan drifts
- pale shelf ice glimpses
- near-black open water
- sparse rocks/pillars
- whale-rib landmark
- very few pines, concentrated near the Township-side Pass only
- rare warm navigation accents

Do not turn Phase A into "Township with fewer buildings."

### 3.2 Route

1. **Township Gate / expedition boundary**
   - Existing Township `PartyGate` remains the transition authority.
   - Crossing loads/activates the Phase A Frozen Coast room/space.
   - No bespoke transition input.

2. **Pass**
   - Narrow approximately 5 m route.
   - Orange trail stakes/sign language may remain simple.
   - Primary job: create a departure beat and hide the wider coast until the lateral reveal.

3. **Pass exit / lateral reveal**
   - The coast should open sideways rather than straight north.
   - The player should see enough of Driftfield to understand that the expedition has begun without seeing the entire region.

4. **Driftfield**
   - Open first-combat bowl, approximately 30 m scale from the concept.
   - 4 hard pillars.
   - 3 boulders.
   - 6 barchan drifts.
   - Whale-rib cage/arc used as landmark + collision.
   - East shoreline is a hard hazard/boundary.
   - Two broad figure-eight kiting loops.
   - Tuskbull lanes should naturally terminate at pillars or whale ribs.

5. **Phase A stop**
   - The crevasse/arch edge is visible.
   - Ice Arch is closed/inaccessible.
   - Broken Shelf is fenced off by drift/blocked geometry.
   - No water/fall/rescue system.

### 3.3 World collision rules

Use simple static 2D collision.

Hard objects:
- pillars
- large boulders
- whale ribs
- cliff boundaries
- shoreline boundary

Soft drift:
- does not hard-stop normal player movement unless existing geometry requires it.
- for Tuskbull, it slows the charge but does not cause a crash/stun.

Tuskbull collision language is locked:
- **hard object -> crash + stun**
- **soft drift -> reduced charge speed, no stun**

Do not build dynamic snow physics.

## 4. Enemy contracts

All numbers below are **initial playtest values**, not locked balance. Reuse current enemy seams and current tuning where sensible.

### 4.1 Rolly

Purpose:
- low-cost swarm pressure
- keeps automatic weapons busy
- makes crowd-control/area weapons meaningful

Presentation:
- small pale snow-seal/blob body
- indigo underside/core
- amber hostile eyes
- strong compact ground shadow/contact
- never rely on white-on-white silhouette alone

State model:
1. SPAWN
2. PURSUE nearest living penguin
3. SQUASH tell near attack range
4. BELLY_LUNGE / contact hit
5. short recover
6. PURSUE

Rules:
- groups should feel like loose flocking rather than a perfect ring.
- no ground telegraph decal.
- body squash is the tell.
- low HP.
- direct pursuit is acceptable for Phase A.
- actors do not need to block one another.

Acceptance:
- readable on snow at gameplay camera distance.
- 5-8 on screen still read as a swarm rather than visual static.
- Snowbomb clearly rewards clumping.
- Fish Spear can pierce a short line when Rollies align.

### 4.2 Skua Slinger

Purpose:
- ranged pressure
- forces players to leave comfortable loops/cover
- makes the player look away from the nearest pursuer

Phase A simplification:
- DO NOT build runtime perch discovery.
- Hard-author exactly 3 approved Driftfield perch points on the concept pillars.
- Maximum 2 active Skuas in a Phase A encounter.

State model:
1. PERCH_IDLE
2. ACQUIRE target
3. WINDUP
   - wing/body raise
   - amber arc dots may preview trajectory
4. LOCK landing point
   - red landing ring
5. THROW ice egg
6. RECOVER
7. if threatened/approached, HOP/FLEE to another authored perch
8. PERCH_IDLE

Projectile:
- non-homing after release.
- visible arc.
- small area burst on landing.
- room-bounded and cleaned at encounter end.
- reuse current projectile/damage seams where practical.

Rules:
- do not require navigation/pathfinding.
- transition among authored perch positions only.
- dark body/yellow beak remain visually distinct from Tern Buddy later.

Acceptance:
- player can identify which location will be hit before impact.
- projectile does not home after commitment.
- 2 simultaneous Skuas do not create unreadable decal soup.
- Slingshot provides the clearest ranged answer.

### 4.3 Tuskbull

Purpose:
- lane charger
- makes terrain an active combat tool
- teaches bait -> dodge -> crash -> punish

State model:
1. SHUFFLE / pursue pressure
2. SELECT target
3. WINDUP
   - rear/snort/snow streak
   - translucent red-orange lane with solid red boundaries
   - amber direction chevrons
4. COMMIT CHARGE
   - target lane no longer tracks player
5a. HARD IMPACT
   - pillar/rib/approved hard collider
   - stop
   - STUN
   - punish window
5b. SOFT DRIFT
   - remain in charge
   - reduce speed while inside drift
   - no stun
5c. MISS / lane completes
   - stop/recover
6. RECOVER
7. SHUFFLE

Implementation bias:
- reuse/adapt the existing charger EnemyBehavior rather than creating a second charge architecture.
- impact classification may use simple collider groups/metadata such as `tuskbull_hard_stop` and `tuskbull_soft_drift`.
- no physics-material system.
- no general destructible environment.

Telegraph:
- never use the giant opaque concept arrow.
- lane fill is translucent.
- boundaries remain strong.
- players standing in the lane remain visible.

Acceptance:
- charge can be baited deliberately into every approved pillar/rib target.
- hard collision always yields a reliable stun.
- drift reduces charge speed without producing a stun.
- dodge sideways is understandable without tutorial text.
- in 4P, target selection is stable enough that players can read who is being threatened.

## 5. Weapon contracts

Underlying WeaponRack rules remain locked:
- six real slots
- independent cooldowns
- duplicates occupy real slots and both function
- no direct upgrade/merge UI
- attack behavior remains automatic

Presentation rule:
> Brotato underneath. Penguin adventure game on the surface.

No permanent six-weapon chandelier. The penguin stays visually readable.

### 5.1 Fish Spear

Family: held melee.

Behavior:
- short straight thrust.
- approximately 1.3 m concept reach.
- narrow line.
- pierces enemies in the short line.
- medium cadence.
- best when a target is exposed/stunned or Rollies line up.

Presentation:
- carried/stowed cleanly outside active combat.
- on attack, present spear from a flipper-side anchor and thrust.
- one small additive visual pose/lean is enough.
- gameplay damage timing remains separate from sprite motion.

Duplicate behavior later:
- alternate sides/timing.
- do not permanently display multiple spears around the penguin.

Acceptance:
- can hit multiple Rollies only when they are actually aligned in the narrow thrust.
- strong against a stunned Tuskbull because of timing/opportunity, not a hidden damage multiplier.

### 5.2 Icicle Slingshot

Family: held ranged.

Behavior:
- rapid single-target shots.
- long range.
- nearest/valid target preference can reuse current automatic targeting.
- intended to reach Skua perches quickly.
- projectile identity comes from a bright shard + short trail.

Implementation:
- use the smallest friendly projectile solution compatible with existing DamageEvent and room bounds.
- do not create a universal projectile framework if the existing enemy snowball/projectile seam can be safely adapted.

Presentation:
- small held Y-fork.
- tiny pull-back/recoil.
- projectile carries most visual readability.

Acceptance:
- can hit a perched Skua from normal Driftfield floor positions.
- does not pierce by default.
- trail remains below enemy telegraphs in visual priority.

### 5.3 Snowbomb

Family: thrown arc.

Behavior:
- slow cadence.
- chooses a useful cluster in range.
- arcs/lobs to a committed target point.
- area burst, approximately 1 m concept radius.
- especially rewarding against Rolly clumps.
- may arc over drifts/ribs rather than requiring direct line of sight.

Targeting simplification:
- "largest group in radius" is enough.
- no full LOS solver.
- if cluster targeting becomes unexpectedly complex, use nearest target position plus a small local-neighbor count and STOP rather than building a spatial-query framework.

Presentation:
- snowball/bomb appears in flipper.
- short overhand lob.
- soft amber landing indicator only.
- enemy red is reserved for danger telegraphs.

Acceptance:
- visibly rewards grouped Rollies.
- projectile/arc is readable.
- landing indicator cannot be confused with Tuskbull/Skua danger red.
- no friendly fire.

## 6. First Driftfield encounter sequence

These counts are **starting playtest values only**. Tune after human play.

The purpose is progressive teaching, not difficulty escalation for its own sake.

### Wave 1 - Swarm lesson
1P baseline:
- 6 Rollies

For each extra player:
- +2 Rollies

Teach:
- movement loop
- auto-attacks
- Fish Spear line opportunities
- Snowbomb clump value

No Skua. No Tuskbull.

### Wave 2 - Look away from the swarm
1P baseline:
- 6 Rollies
- 1 Skua

Extra players:
- +2 Rollies each
- add a second Skua only at 3-4 players

Teach:
- red landing ring
- leaving a comfortable line
- ranged reach
- maintaining swarm awareness while responding to artillery

### Wave 3 - Environment as a weapon
1P baseline:
- 8 Rollies
- 1 Tuskbull

Extra players:
- +2 Rollies each

Teach:
- charge lane
- sideways dodge
- pillar/rib crash
- punish window

No Skua in the first Tuskbull lesson.

### Wave 4 - Mixed proof
1P baseline:
- 8 Rollies
- 1 Skua
- 1 Tuskbull

Extra players:
- +2 Rollies each
- second Skua at 3-4 players only

Goal:
- prove whether the three roles remain readable together.
- prove whether Spear/Slingshot/Snowbomb create different useful jobs without hard counters.

Stop adding enemies if the field becomes visually noisy. Spawn cadence should solve emptiness before adding props or new enemy types.

## 7. Spawn behavior

Phase A should use authored Driftfield spawn markers rather than arena-perimeter math if that seam can be added locally.

Preferred marker groups:
- swarm west
- swarm east
- swarm north
- Skua perch markers
- Tuskbull lane-entry markers

Rules:
- never spawn directly on a living player.
- Rollies can enter in loose clusters.
- Skua spawns/appears at a valid authored perch.
- Tuskbull should enter where at least one readable hard-impact lane exists.

Do not add navmesh/pathfinding.

## 8. Visual priority

Locked order:
1. player identity
2. enemy danger telegraphs
3. enemies
4. weapon attacks
5. decorative effects

Consequences:
- Tuskbull lane stays translucent.
- Skua landing ring stays red but compact.
- Snowbomb landing ring stays amber.
- Rolly gets no ground decal.
- weapon trails remain thin/short-lived.
- four-player scarf/indicator readability must survive the mixed wave.

## 9. Co-op behavior

No new co-op subsystem.

Existing party rules remain authoritative.

Phase A should naturally support:
- one player baiting Tuskbull while others punish
- one player reaching Skua while others manage swarm
- Snowbomb player controlling Rolly clumps
- multiple players independently carrying duplicates/loadouts

Enemy targeting:
- nearest/selected living player using existing party query seams.
- Tuskbull locks its charge target at telegraph commit.
- Skua locks landing point before throw.
- dead/downed players are excluded per existing targeting rules.

## 10. Phase A acceptance tests

### Route / room
- Township PartyGate enters Frozen Coast Phase A.
- Pass reveal leads naturally into Driftfield.
- Phase A cannot proceed beyond the closed arch.
- no Broken Shelf access.
- no accidental water/fall route.

### Rolly
- pursues living players.
- squash tell precedes contact lunge.
- no red ground telegraph.
- readable against snow.

### Skua
- uses authored perch points only.
- target point locks before projectile release.
- landing ring appears before impact.
- projectile is non-homing after release.
- maximum 2 active.

### Tuskbull
- lane locks before charge.
- hard pillar/rib collision -> stun.
- soft drift -> slowdown, no stun.
- miss -> recover, no stun.
- crash/punish window is visible and consistent.

### Fish Spear
- narrow short line.
- pierces aligned targets.
- does not become a permanent floating weapon.

### Icicle Slingshot
- reaches Skua perches.
- single target projectile.
- short readable trail.

### Snowbomb
- committed arc.
- area hit.
- amber landing cue.
- no enemy-red cue.
- can reward clustered Rollies.

### 1-4 players
- player identities remain readable.
- encounter scales without exceeding 2 Skuas.
- no player can force party travel alone.
- party wipe still fails encounter through existing authority.

### Regression
Preserve:
- character contract/scarf
- dash/hit/downed/revive
- Township Visual V1
- locomotion grounding branch behavior
- doorway/travel
- WeaponRack
- economy/Snow
- mobile tests
- existing enemy behavior
- existing room/cave seams

## 11. Build order for Codex

Do not implement everything at once.

1. Frozen Coast Phase A room/space + Township gate transition + closed arch.
2. Driftfield static collision and spawn/perch/lane markers.
3. Rolly.
4. Fish Spear.
5. Wave 1.
6. Skua + Icicle Slingshot.
7. Wave 2.
8. Tuskbull hard/soft environment interactions.
9. Snowbomb.
10. Waves 3-4.
11. 1-4P tests.
12. short runtime playtest capture.
13. STOP for human playtest.

If any step is not fun/readable in isolation, fix that before stacking the next role on top.

## 12. Explicit non-goals

Do not build in Phase A:
- Hole Eel
- Broken Shelf gameplay
- walkable floes
- Wreck Yard
- Lid Boomerang
- Snowman Sentry
- Tern Buddy
- Old Berg
- Ancient Funnel gameplay
- cave interior
- Field Shop
- Larry
- maturation
- boss
- new global traversal framework
- pathfinding/navmesh framework
- final balance
- final audio
- final VFX
- final HUD art

## 13. Human review questions

The Phase A build is successful only if a human playtest can answer these.

1. Does leaving Township actually feel like beginning an expedition?
2. Does the Driftfield feel like a place rather than an arena dropped onto snow?
3. Is Rolly pressure readable and satisfying to clear?
4. Does Skua make the player change attention/position without becoming annoying?
5. Is baiting Tuskbull into hard terrain intuitive and fun?
6. Do Spear, Slingshot and Snowbomb feel meaningfully different?
7. Does each weapon remain useful outside its best matchup?
8. Can four players read the field without telegraph soup?
9. Does the player want another wave/run?

If the answer to #9 is not yes, do not proceed to Phase B.
