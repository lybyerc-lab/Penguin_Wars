# Penguin Wars: adventure architecture

How the town, caves and rooms fit together, and where to plug new work in.
The rules in **Contract** are load-bearing: the tests enforce several of them,
and the rest are what keeps the two runnable scenes from drifting apart.

## Contract

1. **`Expedition` is the only thing that moves the party.** Town to cave, room
   to room, cave back to town. Nothing else changes where the party is.
2. **`RoomDefinition` owns geography** — bounds, entry point, exits, supply
   placement, palette and a reference to an encounter. It never owns combat.
3. **`EncounterDefinition` owns combat content** — enemy scenes, counts, pacing,
   difficulty and an optional boss. It never owns geography.
4. **No second journey, dungeon or world manager.** New data resources are
   welcome; a second thing that decides where the party goes is not.
5. **No global current-room singleton.** Systems are handed their room by the
   composition root. Nothing reaches for "the current room".
6. **1–4 players throughout.** Every system takes a party, not a player.
7. **`RunSession` is the single wiring path**, used by both the arena slice and
   the expedition, so a change to one cannot silently skip the other.

## Layers

| Layer | What lives there | Examples |
| --- | --- | --- |
| Data | Immutable `Resource`s describing content | `RoomDefinition`, `CaveDefinition`, `RegionDefinition`, `EncounterDefinition`, `BossDefinition`, `CharacterDefinition`, `RunModifiers` |
| Systems | Nodes that simulate, each owning one concern | `EncounterDirector`, `RunProgression`, `RunWallet`, `ArenaLoot`, `CastleBuilder`, `PartyRoster` |
| Composition | Roots that wire systems to a place | `Expedition` (town and caves), `TestArena` (single-arena slice), `RunSession` (shared wiring) |

`RoomSpace.apply()` is the hand-off between layers: it takes a `RoomDefinition`
and pushes its geography into the party, director, builder, loot, camera and
backdrop. Systems receive their space; they never look it up.

## Seams

Each of these exists so a feature can be added without touching the rest.
`tests/seams_test.gd` covers all of them.

### Optional boss — `BossDefinition` + `BossActor`

`EncounterDefinition.boss` is optional. When a room has one, the director runs
a boss phase after the final wave, and the room does not complete — so its
exits do not unlock — until the boss is down.

**This branch owns the phase, not the boss.** There is no boss content here on
purpose. To add one:

1. Subclass `BossActor` (`scripts/actors/boss_actor.gd`). It already extends
   `ArenaEnemy`, so damage, knockback, loot and death work with no new code.
2. Override `configure(definition, party_size)` to set body size, resistance,
   collision shape and health. Call `super()` unless setting health directly.
3. Attach an `EnemyBehavior` child named `Behavior` for attacks, exactly as
   `charging_seal.tscn` and `snowball_thrower.tscn` do.
4. Save a scene whose root is that subclass, and a `BossDefinition` pointing at
   it. Add fields to `BossDefinition` freely — boss content is expected to grow
   it.
5. Name the definition in a room's `EncounterDefinition`.

The director reads exactly three fields from `BossDefinition`: `scene`,
`display_name` and `reward`. Everything else is between the definition and the
subclass, so no director change is needed for new boss content.

The director guarantees, in order: `party` is set; `configure()` runs while the
node is still out of the tree, so a `Health.maximum` written there becomes the
starting health; run and room scaling are applied on top, identically to every
other enemy; `arena_bounds` is set from the room, inset by `hit_radius`; the
node is placed at the corner furthest from the living party.

Signals for presentation: `boss_started(boss)` when it enters, `boss_reward(amount)`
when it dies. A boss bar subscribes to those. A boss whose `scene` is missing or
is not a `BossActor` completes the room rather than stranding the party, and
says so with `push_error`.

### Run modifiers and difficulty — `RunModifiers`

A `Resource` of whole-run dials: `enemy_health_scale`, `enemy_damage_scale`,
`income_scale`, `starting_snowflakes`. The default is identity, so a run that
names none behaves exactly as it did before the seam existed.

These **compose with** per-room difficulty rather than replacing it:
`EncounterDefinition.difficulty_multiplier` says how hard this room is relative
to its neighbours; `RunModifiers` says how hard the whole run is. The director
multiplies them in `health_scale()` and `damage_scale()`, and applies the result
to every enemy including a boss.

Difficulty levels are `.tres` files in `resources/modifiers/`. Set
`Expedition.modifiers` to pick one.

### Character selection — `CharacterDefinition`

A selectable penguin: id, name, tint, starting weapon, and whether it needs an
unlock. `RunSession.roster` is the ordered selection; slot N takes `roster[N]`,
wrapping if the list is shorter than the party. `RunSession.DEFAULT_ROSTER`
reproduces the original four.

A selection screen sets `Expedition.roster` and nothing downstream changes.
`PlayerIdentity.character_id` records which character filled a slot, so later
systems can ask without guessing from the colour.

`CharacterDefinition.selectable(campaign)` is the unlock check.

### Campaign and milestones — `CampaignState`

Everything meant to outlive a single run: cleared caves, unlocks, named
milestone counters, and run tallies. It is data, not a manager — `Expedition`
still decides everything; it reads and writes this.

`RunJournal` stays run-scoped and additionally reports into `CampaignState`
when one is attached, which is what makes the town-hall meeting able to react
to more than the current run.

Add a milestone with `mark(&"name")` and test it with `milestone(&"name")`.

### Permanent unlocks and save data — `ProfileStore`

The persistence seam. The default keeps one `CampaignState` in memory for the
process lifetime, so today's behaviour is unchanged and nothing promises the
player a save that does not exist — `is_persistent()` returns false and
`save_campaign()` returns false for "held, not written".

To add saving: subclass, override `load_campaign()` and `save_campaign()` over
`ResourceLoader`/`ResourceSaver` (`CampaignState` is a `Resource` for exactly
this reason), set `is_persistent()` to true, and assign it to
`Expedition.profile`. Nothing else in the game changes, because nothing else
knows where campaign state comes from.

`Expedition.save_profile()` is already called when a cave is cleared and when a
run is lost.

### Multiple caves and regions — `RegionDefinition`

A region is one town room plus the caves reachable from it. `Expedition.region`
is exported data, so a second cave is one entry in a list and a second region is
one resource — neither is a code change. The town draws one cave mouth per cave
in the region, spread automatically.

`RegionDefinition.problems()` returns everything wrong with a region — missing
town, a town room that is not a town, no caves, empty slots, duplicates, and
any cave route that does not resolve. A broken region fails a test rather than
a play session.

Town buildings are still a layout table in `TownHub.SERVICES` because one town
exists. A second town moves that table into region data; nothing else changes.

## Room and cave data

`CaveDefinition` owns the route graph. `RoomExit` names its target by id rather
than holding a reference, so room resources can never form a cycle. Exits with
an empty `target_id` leave the cave for town.

`CaveDefinition.unresolved_exits()` and `RegionDefinition.problems()` are the
validation entry points; both are asserted in tests.

## Invariants the tests hold

- Every existing suite runs against the real scenes, not mocks.
- `tests/seams_test.gd` uses `tests/stub_boss.gd` — a boss with no attacks, art
  or telegraphs — so the boss phase is verified without this branch owning boss
  content.
- What survives a room change (wallets, stats, levels, purchases, health,
  carried weapons) and what does not (enemies, projectiles, drops, snowmen,
  castles) is asserted in `tests/town_cave_test.gd`.
- Castles are refused wherever there is no fight, including town.
- A room's exits stay locked until it is complete, and travel needs the whole
  living party on the pad.

## What this branch deliberately does not own

Bosses, new enemies, campaign balancing and content tuning belong to the
gameplay lane. The seams above are the supported way in; if something needs a
change to `Expedition`, `RoomDefinition` or `RunSession` to work, that is worth
raising rather than working around, because it usually means a seam is missing.
