# Penguin Wars — Project Memory

> Durable project context for future sessions and AI handoffs.
>
> Canonical development authority: `main@2c9a890dfb14c2cad01a0eb9044f4cf8d6a99be6`. Current feature candidate: `feature/evolution-checkpoint-v0`, cut from that main baseline. It adds a dedicated timing prototype only; it does not alter ordinary expedition progression.

## North-star concept

**Penguin Wars = Brotato's run/build engine traveling through a compact Zelda-like adventure world.**

The game should feel immediately playable, highly replayable, readable in local co-op, and handcrafted rather than procedural-corridor-heavy.

Core inspirations:

- **Brotato**: short runs, radical character builds, weapon synergies, personal economy, reroll/lock/shop decisions, difficulty ladder, fast restart loop.
- **Classic Zelda**: physical rooms, environmental branches, secrets, traversal tools, locked passages, bosses, shortcuts, recognizable places.
- **Penguin Wars identity**: snowy storybook world, tiny serious civilization, physical comedy, dry penguin attitude, absurd war treated as normal.

Working rhythm:

```
Explore → discover → fight swarm → collect Snow / XP → acquire build pieces → commit → survive → mature → push deeper → boss
```

Persistent design anchor:

> Every run makes you stronger temporarily. Every adventure makes the world permanently more open.

## Current implementation state

Godot 4.7.x, GL Compatibility renderer, desktop-first with Android/mobile support kept foundational.

Current important lineage:

- `main@03b9fac`: original arena foundation.
- `integration/adventure-base@e4c946b`: Claude architecture freeze.
- `antigravity@938c54c`: unified boss gameplay port.
- `antigravity@9fae195`: recovered full-screen Brotato-like presentation and corner HUD.
- `antigravity@20ed8f9`: physical Zelda-style doorway thresholds replacing teleport pads.
- `antigravity@f05d804`: chunky carved cave mouths, palette-aware tunnel depth, environmental route framing, wider Kelphollow expedition mouth and polished barricade presentation.
- `antigravity@46efa8d`: current gameplay authority before the six-slot rack branch.
- `cleanup/pre-brotato@8f778b0`: doorway offset and presentation data, corrected render fixtures and viewport verification.
- `integration/pre-brotato-rack`: cleanup and six-slot rack baseline.
- `main@4dad4a0`: canonical development authority for this integration.
- `integration/build-intensity-baseline`: combined Tier I–IV weapon, chunky Snow, and progression-direction baseline.
- `main@2c9a890`: canonical development authority after that integration.
- `feature/evolution-checkpoint-v0`: dedicated six-wave maturation-timing proof above `main@2c9a890`; not merged into main.

Current implemented slice includes:

- 1–4 player local-party foundation.
- Two-player default keyboard play, gamepad slots for more players.
- Shared camera.
- Auto-target basic weapons.
- Personal six-slot `WeaponRack` runtimes; standard loadouts begin in slot 0.
- Immutable Ice Lance and Fish Cleaver Tier I–IV chains, rack merge APIs, and canonical weapon-class aggregation.
- Player-wide flat weapon damage used by Sharp Ice and Cold Forge Hone.
- Chunky physical Snow loot: SMALL, CHUNKY, BIG, and JACKPOT value tiers with landing, wobble, magnet suction, and collection puff presentation.
- Manual movement and dodge.
- Personal health, XP, wallet, and transitional upgrade choices.
- Snow-castle defense prototype.
- Seal raider, charging seal and snowball thrower.
- Kelphollow prototype town.
- Hollow Shelf first branching cave.
- Room-owned bounds and palettes.
- Physical room exits through `PartyGate`.
- Frostbreaker boss at Black Ledge.
- Glacier Warden and Mondo boss definitions/content ready for future milestones.
- Event-driven boss HUD.
- Full-screen combat presentation with compact corner cards.
- Android/mobile arena path and touch UI.

## Frozen architecture contract

This is the most important technical memory. Do not casually violate it.

### Ownership

- **Expedition** is the only authority that moves the party between town, cave and rooms.
- **RoomDefinition** owns geography: bounds, entry, exits, supplies, palette and encounter reference.
- **EncounterDefinition** owns combat setup: enemy scenes/count/pacing/difficulty/optional boss.
- **CaveDefinition** owns the route graph.
- **PartyGate** owns the shared co-op rule for traversing an exit.
- **RunSession** is the shared wiring path for arena and expedition.
- **RoomSpace.apply()** pushes room geometry into party, director, builder, loot, camera and backdrop.
- **RunModifiers** owns whole-run difficulty scaling.
- **BossSchedule** is selection-only data based on GLOBAL RUN WAVE.
- **CharacterDefinition / CharacterTrait** are the character-content seams.

### Forbidden architecture creep

Do not introduce:

- a second journey manager,
- a second dungeon/world manager,
- a global current-room singleton,
- room-local systems reaching sideways to discover current room state,
- a second combat path just for bosses,
- difficulty logic inside BossSchedule,
- viewport-dependent gameplay geometry,
- paid run-power shopping in Township as a second Field Shop.

Historic names that must **not** be restored as competing authorities:

- CaveJourney
- CaveDungeonDirector
- DungeonFloorPlan

## Doorway/traversal direction

Teleport pads are retired as the intended presentation.

Current mechanic:

- `RoomExit.Side`: LEFT / RIGHT / TOP / BOTTOM.
- `PartyGate` remains the actual co-op travel object.
- Doorway threshold is rectangular and orientation-aware.
- All living penguins must enter.
- Downed penguins do not block travel.
- Dwell is short (~0.4 s).
- Locked exits physically refuse travel.
- Room clear/boss defeat opens the passage.
- Entry placement occurs near the opposite wall in the destination room.

Design goal:

> Rooms should feel physically connected. The player walks through a place, not activates a level selector.

Planned polish:

- Chunky cave-mouth silhouettes.
- Wall thickness/recess rather than black rectangles.
- Palette-aware tunnel interiors.
- Environmental path/scuffs around doors.
- Glitter Seam exit reads calm/crystalline.
- Cracked Gallery reads rough/dangerous.
- Kelphollow cave mouth gets a special expedition-entrance treatment.
- Eventually add a short classic Zelda-style directional screen slide.

Implemented doorway seams:

- `RoomExit.offset_along` persists each doorway's wall offset, and `place_on()` is the shared placement path for gates and wall art.
- `RoomExit.Presentation` explicitly selects `STANDARD`, `EXPEDITION_MOUTH`, `CRYSTAL`, or `FRACTURED` dressing; doorway visuals do not infer it from target ids or room names.
- Multiple doorways can share a wall without their placement or presentation drifting.

## Presentation direction

The recovered presentation at `9fae195` is the intended baseline.

- World/playfield should own essentially the entire screen.
- HUD floats over the world.
- Player cards live in corners.
- Top-center text is minimal: room + wave/state.
- Boss bar sits near top-center without displacing gameplay.
- Do not return to a giant permanent HUD strip.

Current player-card concept:

- portrait
- player/scarf color
- health
- level
- personal Snow
- compact six-weapon row, with occupied icons and visible empty slots
- compact Roman tier marker on every occupied weapon slot

Room variation should primarily come from:

- interior geometry
- landmarks
- alcoves
- hazards
- ice formations
- obstacles
- exits

Not from shrinking the playable rectangle into tiny boxes.

Typical combat-room target: roughly 1200 × 620–660 logical space at 1280×720 presentation.

## Weapon rack integration notes

`WeaponRack` is a personal runtime under each penguin. It owns ordered
definitions and independent `WeaponController` instances; shared
`WeaponDefinition` resources remain immutable. `RunSession` applies each
`CharacterDefinition.starting_weapons` loadout once, beginning in slot 0, and
`weapon_capacity` provides the future one-flipper-style exception seam.

Each weapon definition carries a stable `family_id`, a Tier I–IV value, a
`next_tier` reference, and canonical class tags from `WeaponClasses`. The rack
merges matching non-maximum definitions through its slot and incoming-definition
APIs, leaving all unrelated slot positions intact. Its class aggregation counts
each occupied weapon once, and is the seam for future set bonuses and shop
weighting. Tier chains currently ship for Ice Lance (Ice + Precision) and Fish
Cleaver (Fish + Blade). Sharp Ice and Cold Forge Hone write
`PlayerStats.flat_weapon_damage`, so every present and later-equipped weapon
for that player reads the same flat damage bonus.

Merging is an internal evolution primitive, not a player-facing ordinary-run
command or automatic duplicate policy. Duplicate weapons remain independently
firing rack occupants and are themselves a six-slot commitment choice.
`WeaponRack.resolve_maturation_once()` resolves every valid pair visible in one
event-start snapshot, preserving the lower slot and never cascading created
tiers. It returns `WeaponMaturation` result data and emits `matured(changes)`
only if it made changes. The rack owns no timing policy. The dedicated Evolution
Checkpoint v0 prototype invokes it after wave five for every registered player,
including downed members; normal arena and expedition runs do not invoke it.
Later progression policy can revise timing beyond that contained proof.

## Progression direction

The approved direction is **Acquire → Commit → Survive → Mature**. Players
acquire weapons and future items/relics, commit scarce rack capacity and build
identity, then resolve that accumulated commitment only at future meaningful
maturation moments. Direct weapon or skill upgrading during an expedition is
not the intended mature loop.

Current XP level-up choices, paid `UpgradeDefinition` offers, Sharp Ice, and
Cold Forge Hone are transitional prototype infrastructure. `PlayerStats` and
its player-wide flat-damage seam remain useful simulation state; this decision
changes how players acquire modifiers, not whether the simulation can express
them. Exact evolution timing and the eventual role of XP or Expedition Rank are
unresolved. The future Field Shop is for weapons, items/relics/passives, build
identity, rerolls, locks, and personal Snow spending rather than generic stat
shopping.

## Snow pickup presentation

World Snow uses physical chunky loot rather than literal six-spoke snowflakes.
Its visual tier follows value without changing economy semantics: SMALL is 1–2,
CHUNKY 3–5, BIG 6–9, and JACKPOT 10+. Snow lands with an arc, squash and rebound,
wobbles while grounded, accelerates toward a living player within that player's
pickup radius, and finishes with a short collection puff. The HUD may continue
to use the ❄ symbol and the player-facing name remains Snow. `RunPickup.Kind`
keeps its current internal `SNOWFLAKE` name for compatibility.

Known limits deliberately left for later systems work:

- each equipped controller scans target groups independently, so 4 players × 6 weapons needs profiling before mobile-scale content expands.
- Snow's cosmetic shape selection includes `get_instance_id()`, so it is not guaranteed reproducible across separate runs; this is not gameplay state.

## Boss architecture and content

Boss scaling contract:

1. Boss content calls/uses `BossActor.configure(definition, party_size)`.
2. Party-size HP scaling is owned by `BossDefinition.scaled_health()`.
3. `configure()` returns.
4. `EncounterDirector` applies room difficulty × RunModifiers exactly once.
5. Boss content must not reapply those multipliers.

Art size and gameplay size are independent:

- `visual_scale` = presentation
- `hit_radius` = gameplay balance

Current boss milestones target:

- Wave 5: Frostbreaker
- Wave 10: Glacier Warden
- Wave 15: Frostbreaker placeholder, eventually an evolved/different mini-boss
- Wave 20: Mondo, the War King

BossSchedule counts **global run waves**, not cave number and not room-local wave number.

Current boss identities:

### Frostbreaker
- Mini-boss.
- Rush/charge-focused.
- 500 base HP.
- 16 base damage.
- First boss prototype.

### Glacier Warden
- Mid-tier boss.
- Rush + volleys.
- 1100 base HP.
- 22 base damage.

### Mondo, the War King
- Major boss.
- Rush, volley, slam.
- Enrages below 50% HP.
- 2400 base HP.
- 28 base damage.
- Intro line idea: **“Penguins. You have been extremely annoying.”**

## Multi-agent workflow

The project intentionally uses multiple AI agents.

Roles:

- **User**: creative director, playtester, final taste authority.
- **ChatGPT**: integration/design/QA referee, architecture continuity, handoffs, repository audit.
- **Claude/Opus lane**: architecture-heavy changes, seams, world/run structure when available.
- **Antigravity/AG**: concrete gameplay/content/presentation implementation and testing.
- **Gemini Flash High**: useful for well-specified implementation when architecture is already fixed.

Rule:

> Agents should hand work to the same architecture, not build competing implementations.

Before approving agent work, inspect the actual pushed GitHub branch/head, not only its completion report.

## Player testing preference

Human feel-testing is essential.

Automated tests prove plumbing, not fun.

When a playable pass lands, prioritize:

- movement feel
- dodge readability
- camera behavior
- room scale
- combat density
- branch readability
- boss telegraph clarity
- visual hierarchy
- “does this feel like an actual game rather than a test harness?”

The user strongly prefers polished, coherent progress over endless planning or throwaway prototypes.
