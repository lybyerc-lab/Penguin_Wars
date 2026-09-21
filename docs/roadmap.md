# Penguin Wars — Roadmap

This is a direction document, not a promise of exact scheduling. The order matters more than the dates.

## Current baseline

Implementation baseline recorded here:

`antigravity@f05d804`

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

The first doorway art-polish pass is complete. Human playtest now decides whether presentation is locked or needs another targeted pass before Snow pickups.

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

### 0.2 Doorway offset seam

Before multiple cave mouths occupy the same wall:

- add `RoomExit.offset_along`
- use it in `wall_position()`
- remove dead/ambiguous legacy positioning behavior

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

## Phase 1 — Snow pickup feel

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

Preserve existing wallet/XP seams while art/feel changes.

## Phase 2 — Weapon Rack foundation

Goal: make the build engine capable of Brotato-like inventory decisions.

Deliver:

- dedicated personal weapon rack/inventory runtime
- up to 6 ordinary weapon slots
- current single weapon becomes slot 0 migration path
- CharacterDefinition.starting_weapons feeds rack
- UI row in PlayerCornerHUD becomes real
- per-player ownership
- no global weapon inventory

Do not add every weapon yet. First prove the slot architecture.

## Phase 3 — Weapon tiers, merging, classes

Deliver:

- Tier I–IV
- duplicate merge rules
- weapon class/tag data
- class count aggregation
- class/set-bonus seam
- shop weighting seam
- recycle/sell rules if useful

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

Add a small representative weapon set before large content expansion.

## Phase 4 — Real Field Shop

Goal: replace the current temporary upgrade UI with the true between-wave run shop.

Deliver:

- 4 offers per player
- buy
- reroll
- lock
- price/reroll escalation
- weapon offers
- passive/item offers
- class-aware weighting
- merge awareness
- ready-up
- controller + mouse + touch consideration

Township stays separate.

## Phase 5 — Level-up system cleanup

Deliver:

- 4 upgrade choices per level
- rarity tiers
- stat categories
- readable comparison
- personal choice queues
- no choices stranded on room transition

Current quick-upgrade prototype can then retire.

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
