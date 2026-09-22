# Penguin Wars — Roadmap

This is a direction document, not a promise of exact scheduling. The order matters more than the dates.

## Current baseline

Implementation baseline recorded here:

`integration/evolution-feel-v1` (systems-playtest candidate above
`main@2c9a890`: Evolution Checkpoint, timed combat feel, and CharacterVisual
state architecture). `main@2c9a890` remains canonical development authority.

At that point the project has:

- unified Expedition/RoomDefinition architecture
- 1–4 player local co-op foundation
- branching Hollow Shelf cave
- fullscreen Brotato-like presentation
- PlayerCornerHUD
- physical Zelda-style doorway thresholds
- Frostbreaker boss
- Warden and Mondo boss content ready
- current prototype economy/upgrades/castles
- Android/mobile support path
- six-slot personal weapon rack, Tier I–IV merge chains, and class aggregation
- chunky physical Snow pickup feel with preserved economy semantics
- timed Brotato-like combat heartbeat and automatic intermissions in one opt-in prototype
- visible stable multi-weapon mounts and deterministic duplicate staggering
- CharacterVisual downed/revive state plumbing; runtime character-art fidelity remains pending

The first doorway art-polish pass and Snow pickup feel pass are complete. The
first evolution timing proof now lives only in the dedicated Evolution
Checkpoint prototype; it is not ordinary expedition progression.

## Phase 0 — Presentation lock

Goal: make the current slice look like a game, not a systems prototype.

### 0.1 Doorway art polish — IMPLEMENTED at `f05d804`

Implemented targets:

- Kelphollow cave mouth
- side doorway silhouettes
- wall thickness/recess
- non-black tunnel depth
- environmental floor grounding
- Glitter vs Cracked route language
- boss barricade art
- route-label hierarchy
- quieter waiting copy

### 0.2 Doorway offset seam — IMPLEMENTED at `cleanup/pre-brotato@8f778b0`

Before multiple cave mouths occupy the same wall:

- `RoomExit.offset_along` and shared `place_on()` placement
- explicit `RoomExit.Presentation` dressing data
- no doorway presentation branches on target ids or room names

### 0.3 Human playtest

Check:

- full-screen readability
- doorway feel
- room scale
- co-op waiting behavior
- route clarity
- boss-bar placement
- mobile survivability

Do not advance if presentation still feels obviously prototype-level.

## Phase 1 — Snow pickup feel — IMPLEMENTED on `integration/build-intensity-baseline`

Replace literal world snowflakes with chunky Snow.

Deliver:

- 3–4 blob/chunk sizes
- value tiers
- bounce/land squash
- wobble/roll
- magnet suction
- collection pop/splat
- oversized jackpot lump
- HUD keeps ❄ symbol if useful
- resource copy standardized to “Snow”

Implemented: SMALL / CHUNKY / BIG / JACKPOT value tiers, landing feel, grounded
wobble, magnet suction using `pickup_bonus`, collection FX, and preserved wallet
and XP semantics. World loot is chunky Snow; the HUD may retain ❄.

## Phase 2 — Weapon Rack foundation — IMPLEMENTED at `codex/weapon-rack-foundation@44296b8`

Goal: make the build engine capable of Brotato-like inventory decisions.

Deliver:

- dedicated personal `WeaponRack` runtime
- six ordinary slots, with a per-character capacity field for later exceptions
- the former single weapon migrated to slot 0
- `CharacterDefinition.starting_weapons` feeds the rack through `RunSession`
- PlayerCornerHUD and Build Sheet report slots and occupancy
- independent per-player `WeaponController` instances
- no global weapon inventory

Do not add every weapon yet. First prove the slot architecture.

## Phase 3 — Weapon tiers, merging, classes — IMPLEMENTED on `integration/build-intensity-baseline`

Deliver:

- Tier I–IV immutable definition chains for Ice Lance and Fish Cleaver
- duplicate merge rules in the personal `WeaponRack`, including an incoming-definition seam for a future shop
- canonical weapon class/tag data and class count aggregation
- `WeaponRack.class_counts()` / `class_count()` seam for future class or set bonuses
- `WeaponRack.find_merge_slot()` seam for future shop weighting and merge-aware offers

Initial class list:

- Fish
- Blade
- Harpoon
- Snow
- Ice
- Heavy
- Precision
- Engineering
- Support
- Royal
- Swift
- Explosive

The current representative set is Ice Lance (Ice + Precision) and Fish Cleaver
(Fish + Blade). Merge APIs are internal evolution primitives: no merge UI,
ordinary-run automatic duplicate merge, or maturation-timing policy is
implemented. The contained Evolution Checkpoint proof resolves once after Wave
5; duplicate weapons otherwise remain independently firing slot commitments.
Shop offers, recycle/sell rules, and class bonuses remain future systems work.

## Phase 4 — Real Field Shop

Goal: replace the current temporary upgrade UI with a between-wave run shop for
acquiring and committing build pieces.

Deliver:

- 4 offers per player
- buy
- reroll
- lock
- price/reroll escalation
- weapon offers
- item/relic/passive offers
- class-aware weighting
- six-slot pressure and duplicate-commitment visibility
- ready-up
- controller + mouse + touch consideration

Township stays separate.

## Phase 5 — Build Intensity & Evolution

Goal: turn accumulated run commitment into delayed progression without direct
weapon or skill upgrade shopping.

Future questions:

- what contributes to weapon intensity?
- when does maturation resolve?
- can one maturation event advance only one tier?
- how should duplicate slot commitment work?
- how do classes and future items influence character skill maturation?
- what role does XP or Expedition Rank play?
- how is evolution communicated clearly?

The current quick-upgrade prototype remains functional while this direction is
prototyped. It is not the intended final level-up loop.

### Evolution Checkpoint v0 — IMPLEMENTED on `feature/evolution-checkpoint-v0`

`scenes/prototypes/evolution_checkpoint.tscn` is a six-wave, one-player proof
using the normal `TestArena` and `RunSession` composition path. It opts into
20 / 25 / 30 / 35 / 40 / 45-second timed waves with a three-second automatic
intermission. At its Wave-5 timed completion only, every registered party rack
resolves one snapshot-based maturation event. Wave 6 therefore uses the evolved
rack. Normal arena and expedition runs do not subscribe to this policy. The
checkpoint carries no shop, items, skills, recycle, sell, or
permanent-progression work.

### Evolution feel presentation — IMPLEMENTED AS PROTOTYPE on `integration/evolution-feel-v1`

The checkpoint combines the timed combat heartbeat, stable visible weapon slots
and deterministic duplicate staggering with CharacterVisual state plumbing.
The Broad 2.5D concept/reference is approved, but the current in-game art is
temporary scaffolding and is not accepted as a faithful reproduction; a
dedicated production-character fidelity pass must replace assets while retaining
the state machinery. Its cartoon downed/revive presentation is cosmetic; no
revive gameplay was added. Human play acceptance remains pending, and this does
not freeze Wave 5, exact production durations, production-wide timed encounters,
or a final 20-wave RunPlan.

Its provisional tuning uses **compressed prior investment**, rather than the
former linear tier curve: I is about one Tier-I copy worth, II about two, III
about four, and IV about eight. Tier II therefore conserves or slightly improves
the simple damage-per-cooldown of its two consumed Tier I weapons; the freed slot
is an additional reward. Tier III/IV values are monotonic placeholders, not final
balance work.

## Phase 6 — RunPlan / global 20-wave structure

Only now wire the global run plan.

Deliver:

- global run-wave counter
- chapter/room-wave assignment data
- BossSchedule caller through Expedition or a lightweight data plan
- 5/10/15/20 milestones
- room transitions between wave clusters
- no BossSchedule calls from EncounterDirector
- no second run manager

Target flow:

```
waves 1–3   cave entrance
waves 4–6   branch 1
waves 7–10  deeper cave
waves 11–14 branch 2
waves 15–19 dangerous depths
wave 20     major boss
```

Exact mapping can evolve after playtesting.

## Phase 7 — Harvest / run economy redesign

Move Harvest from the current transitional multiplier toward the intended compounding wave economy.

Deliver:

- wave-end Harvest payout
- compounding/growth rule
- Snow + XP interactions
- Luck interactions
- reserve/carry rules
- Hoarder/economy-character seams

Balance after the real Field Shop exists, not before.

## Phase 8 — Character identity pass

Begin building named characters only when the core run systems can express them.

First candidates:

- Squish Squish
- BurrowFoot
- Big-un
- Caveman
- Snowquatch

Each must ship with:

- real CharacterDefinition
- at least one rule-changing CharacterTrait
- readable identity
- starting weapon/loadout
- explicit art scale and collision scale
- no special-case character name logic in Player

Rule:

> If a character can be represented only as +X% stats, it is not finished.

## Phase 9 — Township redesign

Rebuild Township around the actual mature run systems.

Target services:

- Expedition Gate
- Armory
- Fish Market
- Town Hall
- Training Yard
- Lodge/Docks
- Quick Start / expedition bell

Remove or repurpose transitional paid run-power services.

Goal:

> veteran player can start a fresh run from town in ~10 seconds.

## Phase 10 — Storm difficulty

Implement Storm 0–5 as structural run variation.

Possible progression:

- enemy variants
- elites
- hordes
- environmental hazards
- special events
- boss mutations
- dual-boss/high-tier variants

Difficulty scaling should compose through RunModifiers.

## Phase 11 — Adventure tools and richer Zelda layer

Add traversal/combat tools:

- Ice Pick
- Flipper Dash
- Bomb Fish
- Snowball Cannon
- Hookfish
- Fire Pepper

Use them to create:

- visible blocked routes
- secrets
- shortcuts
- return-later curiosity
- combat interactions

## Phase 12 — New regions

Potential progression:

1. Kelphollow / first cave network
2. Frozen Coast
3. Ice Caverns / Wrecked Harbor
4. Ancient Temple / Glacier Pass
5. Enemy Fortress

Add region content only after the run engine is fun enough to justify more geography.

## Phase 13 — True Zelda room transition polish

After doorway geometry is stable:

- directional camera slide/wipe
- side-aware entry/exit
- short controlled transition
- no competing room authority
- avoid expensive simultaneous live worlds unless proven necessary

## Phase 14 — Meta progression and unlocks

Meta should be primarily horizontal.

Persist:

- characters
- weapons
- relic/item pools
- regions
- Storm access
- challenges
- cosmetics
- codex
- shortcuts/adventure unlocks where appropriate

Avoid “+50% permanent damage because you played longer.”

## Phase 15 — Content expansion

Once the framework is stable, expand:

- enemy roles
- bosses
- weapons
- items
- characters
- secrets
- room geometry
- factions
- dialogue/flavor
- special events

## Replayability gears

These should ultimately work together:

1. radical characters
2. randomized shop
3. weighted RNG
4. weapon classes
5. weapon merging
6. Storm difficulty ladder
7. horizontal unlocks

## Definition of “ready for content scale”

Do not mass-produce content until all of these feel stable:

- movement
- dodge
- camera
- full-screen HUD
- doorway traversal
- Snow pickup feel
- six-weapon rack
- shop
- merge/classes
- global run-wave plan
- economy
- character trait seam

Content multiplied on unstable systems creates expensive cleanup later.
