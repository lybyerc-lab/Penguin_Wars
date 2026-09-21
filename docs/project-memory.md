# Penguin Wars — Project Memory

> Durable project context for future sessions and AI handoffs.
>
> Documentation baseline: `antigravity@46efa8d` (doorway mechanics plus carved cave-mouth art polish). This documentation was developed on a separate branch while gameplay work continued, then merged forward.

## North-star concept

**Penguin Wars = Brotato's run/build engine traveling through a compact Zelda-like adventure world.**

The game should feel immediately playable, highly replayable, readable in local co-op, and handcrafted rather than procedural-corridor-heavy.

Core inspirations:

- **Brotato**: short runs, radical character builds, weapon synergies, personal economy, reroll/lock/shop decisions, difficulty ladder, fast restart loop.
- **Classic Zelda**: physical rooms, environmental branches, secrets, traversal tools, locked passages, bosses, shortcuts, recognizable places.
- **Penguin Wars identity**: snowy storybook world, tiny serious civilization, physical comedy, dry penguin attitude, absurd war treated as normal.

Working rhythm:

```
Explore → discover → fight swarm → choose upgrade → shop/build → unlock route → secret → boss → deeper
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

Current implemented slice includes:

- 1–4 player local-party foundation.
- Two-player default keyboard play, gamepad slots for more players.
- Shared camera.
- Auto-target basic weapons.
- Personal six-slot `WeaponRack` runtimes; standard loadouts begin in slot 0.
- Manual movement and dodge.
- Personal health, XP, wallet and upgrade choices.
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

Important small technical TODO:

- Add an explicit per-exit wall offset such as `offset_along`.
- `RoomExit.wall_position(bounds, side, offset_along)` already conceptually supports this.
- Needed before multiple exits share the same wall, because current centering would stack them.

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
