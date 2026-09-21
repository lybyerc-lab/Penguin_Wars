# Penguin Wars: adventure architecture

How the town, caves and rooms fit together, and where to plug new work in.
The rules in **Contract** are load-bearing: the tests enforce several of them,
and the rest are what keeps the two runnable scenes from drifting apart.

> **Frozen for the boss port.** This describes the agreed integration target.
> Change it only if a port uncovers a genuinely missing seam, and say so rather
> than working around it.

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
purpose.

#### The scaling contract

The one rule boss content must not break. Every combat value on
`BossDefinition` is a **base**. After `configure()` returns, `EncounterDirector`
multiplies the instance's health and damage by room difficulty
(`EncounterDefinition.difficulty_multiplier`) and by the run's `RunModifiers`,
through `health_scale()` and `damage_scale()`. **Boss content must never apply
either multiplier itself**, or it lands twice.

Party-size scaling is the exception: it belongs to the boss, so it lives in
`BossDefinition.scaled_health(party_size)` and is applied during `configure()`.
Call that helper rather than reimplementing the formula, so co-op scaling
cannot drift between bosses.

`tests/seams_test.gd` pins the arithmetic: a 300-health boss with 0.5 party
scaling, two penguins, room difficulty 1.5 and a 2.0 run modifier must end at
450 after configure and 1350 after the director. A boss that reapplied would
show 4050.

#### `BossDefinition` fields

| Field | Who reads it |
| --- | --- |
| `id`, `display_name`, `scene`, `reward` | `EncounterDirector` — the only fields it reads |
| `maximum_health`, `party_health_scaling`, `damage` | `BossActor.configure()`; base values, scaled afterwards |
| `visual_scale`, `tint`, `rank` | Boss content and a boss bar. Nothing architectural reads `rank` |

Add fields freely — the resource is expected to grow with boss content. Keep
anything new on the content side of that table.

#### Adding a boss

1. Subclass `BossActor` (`scripts/actors/boss_actor.gd`). It already extends
   `ArenaEnemy`, so damage, knockback, loot and death work with no new code.
2. Override `configure(definition, party_size)` for body size, resistance and
   collision shape. Call `super()` unless setting health directly; the default
   takes base health and damage from the definition.
3. Attach an `EnemyBehavior` child named `Behavior` for attacks, exactly as
   `charging_seal.tscn` and `snowball_thrower.tscn` do.
4. Save a scene whose root is that subclass, and a `BossDefinition` pointing at
   it.
5. Name the definition in a room's `EncounterDefinition`.

The director guarantees, in order: `party` is set; `configure()` runs while the
node is still out of the tree, so a `Health.maximum` written there becomes the
starting health; room and run scaling are applied on top; `room_bounds` is set
to the room rect and `arena_bounds` to that rect inset by `hit_radius`, so a
large body cannot overhang the wall while its projectiles still belong to the
whole room; the node is placed at the corner furthest from the living party.

#### Presentation signals

A boss bar needs no polling and no knowledge of combat:

| Signal | Emitted by | Carries |
| --- | --- | --- |
| `boss_started(boss)` | `EncounterDirector` | The `BossActor` that just entered |
| `boss_defeated(boss)` | `EncounterDirector` | The one that just fell |
| `boss_reward(amount)` | `EncounterDirector` | Already paid; for a flourish |
| `presentation_changed` | `BossActor` | Nothing — re-read `title()` and `phase()` |
| `changed(current, maximum)` | the boss's `Health` | The bar's fill |

`BossActor.title()` and `phase()` are what a bar renders; call `announce()`
after changing either. A boss whose `scene` is missing or is not a `BossActor`
completes the room rather than stranding the party, and says so with
`push_error`.

### Milestone boss selection — `BossSchedule` + `BossTier`

Selection only. A schedule answers "which boss, if any, belongs at **global run
wave** N" and nothing else — it never spawns, places, scales or pays.

**It counts run waves.** Not cave numbers, not room-local wave numbers. Wave 7
is the seventh wave of the whole run, whichever room it falls in.

A `BossTier` is one rung, set to either an exact wave (`at`) or an interval
(`every`). An exact wave outranks every interval; among intervals the largest
matching one wins. That expresses the agreed twenty-wave target directly:

| Rung | Run waves it claims | Wins on |
| --- | --- | --- |
| `every = 5` — mini-boss | 5, 10, 15, 20 | 5 |
| `every = 10` — Glacier Warden | 10, 20 | 10 |
| `at = 15` — evolved mini-boss | 15 | 15 |
| `every = 20` — Mondo, the War King | 20 | 20 |

**Nothing calls this yet, and the director must never call it directly** —
that would put milestone rules inside the combat loop. Its eventual caller is
`Expedition`, through a lightweight run/wave plan that *describes* the run and
writes the chosen boss into an `EncounterDefinition`. Such a layer is allowed
precisely because it describes rather than moves: it is not a second journey
manager. It is not built yet.

Escalating difficulty across a long run is deliberately **not** here, and
neither is Storm. Storm will later alter, replace or enhance these milestone
encounters through `RunModifiers` and
`EncounterDefinition.difficulty_multiplier`.

`problems()` reports tiers set to both a wave and an interval, tiers set to
neither, repeated waves, repeated intervals, and bosses with no scene, so a
broken ladder fails a test rather than a run.

### Room-bounded projectiles

A shot belongs to the room it was fired in. `RoomDefinition.bounds` reaches a
projectile down one explicit chain, with no lookups:

```
RoomDefinition.bounds
  → RoomSpace.apply()      → CastleBuilder.room_bounds, live enemies, live castles
  → EncounterDirector      → ArenaEnemy.room_bounds on every spawn, boss included
  → RangedBehavior         → EnemySnowball.room_bounds
  → CastleBuilder          → SnowCastle.room_bounds → CastleSnowball.room_bounds
```

`ArenaEnemy` carries two rects on purpose: `arena_bounds` is the movement
clamp, which a large body insets so it cannot overhang the wall, and
`room_bounds` is the room itself. Anything that needs the room rather than the
actor's movement box reads `room_bounds`.

Projectiles expire `EnemySnowball.WALL_MARGIN` past the room, so a shot visibly
clears the painted lip before it vanishes. The default rect reproduces the
original arena exactly, so an unset shot behaves as it always did.

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

### Character selection — `CharacterDefinition` + `CharacterTrait`

`RunSession.roster` is the ordered selection; slot N takes `roster[N]`, wrapping
if the list is shorter than the party. `RunSession.DEFAULT_ROSTER` reproduces
the original four. A selection screen sets `Expedition.roster` and nothing
downstream changes. `PlayerIdentity.character_id` records which character filled
a slot, so later systems can ask without guessing from the colour.

A character carries four kinds of thing:

| Field | For |
| --- | --- |
| `tint`, `tagline`, `body_scale` | Presentation. `body_scale` resizes the **art only**. |
| `collision_scale` | The hitbox, set separately from the art on purpose. |
| `starting_weapons` | Ordered loadout. `RunSession` hands it once to the player's personal `WeaponRack`, which fills slots in order. |
| `weapon_capacity` | Per-character rack capacity, defaulting to six for ordinary penguins. |
| `starting_stats` | Opening stat changes, applied through the same `apply_upgrade()` seam the shop uses. |
| `traits` | Rule changes. |

**`traits` is how a character changes rules rather than numbers.** Each entry
is a scene whose root is a `CharacterTrait`; `RunSession` instances it as a
child of that penguin and calls `setup(player)` once the penguin is in the tree
and its starting stats are applied. From there a trait may read and adjust that
penguin's stats, listen to its signals, add nodes, or wrap its behaviour.

Nothing anywhere asks "is this the Caveman". A character is a definition plus
the traits it carries, and `Player.gd` names no character. The planned roster
maps onto this without a single special case:

**Art size and hitbox size are independent, on purpose.** How big a target a
penguin is, is a balance decision, never a consequence of how it is drawn.
`body_scale` moves the art; `collision_scale` moves the hitbox; neither touches
the other, and `tests/seams_test.gd` fails if anything couples them.
`RunSession.scale_art()` and `scale_collision()` are public so a
collision-altering trait can use them later.

These names are **reserved**. They enter the project when their traits are
implemented, not as empty definitions:

| Character | Seam it uses |
| --- | --- |
| Squish Squish — "Tiny, but fierce." Fast, tiny, clumsy | `body_scale` and `collision_scale` below 1, chosen separately; `starting_stats` for speed; a trait for the clumsiness rule |
| BurrowFoot — food, survival, homebody economy | `starting_stats`, plus a trait listening for pickups and healing |
| Big-un — tech nerd, engineering specialist | `starting_stats` for Engineering, a trait that changes what castles do |
| Caveman — slow-talking, extremely tough heavy melee | `starting_stats` for armour and speed, `starting_weapons` for the loadout |
| Snowquatch — large penguin cryptid | `body_scale` and `collision_scale` above 1, chosen separately; a trait for whatever makes it strange |

The same principle applies to boss content: `BossDefinition.visual_scale` is
presentation, and `hit_radius` is balance. Deriving one from the other is a
choice to make deliberately, not a default.

A trait belongs to exactly one penguin. For anything party-wide, put the rule
on a system and let the trait talk to it rather than reaching across to other
players. `problems()` reports empty slots, and
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

## Township is not the field shop

Township is a pre-run, meta and setup hub. The field shop is where paid run
power is bought, between waves. They are different things and stay different.

The current healing, revival and blacksmith services in `TownMarket` are
**transitional prototypes**. Do not grow them into a second paid run shop —
new paid run power belongs in the field shop, not in town.

`RunProgression` keeps the two apart:

- **In a room**, `shop_open()` follows the encounter state, and offers are both
  free (earned by levelling) and paid.
- **In Township**, `in_town` is set and only **free** choices can be spent. A
  choice earned underground is never stranded, but Township does not sell
  field-shop offers.

`_offers_open()` is the single place that rule lives.

## Seams held for the next direction

These are not built. They are noted so that whoever builds them knows where
they go, and so nobody builds them somewhere else.

| Planned | Where it belongs |
| --- | --- |
| 20-wave run structure | `EncounterDefinition.wave_count`, already ranged to 20. The director's wave loop needs no change. |
| Run/wave plan | Reserved and approved, not built. A lightweight data layer owned by `Expedition` that describes a run — which waves happen where, and which milestone bosses `BossSchedule` picks — and writes the result into `EncounterDefinition`. It describes; it must never move the party, or it becomes the second journey manager the contract forbids. |
| Field shop: four offers, reroll, lock | `RunProgression`. `OPTIONS` is today's fixed catalogue and `choose(player_id, index)` indexes straight into it — both are the thing an offer system replaces. Expect to keep `pending`, `purchases`, `price()` and the wallet, and to change what an "index" means. |
| Four weapon tiers, duplicate merging | `WeaponDefinition`. A tier field and a merge rule live there and in whatever owns an inventory; `WeaponController` reads a definition and needs no knowledge of tiers. |
| Weapon classes and set bonuses | `WeaponDefinition` for the class tag; `PlayerStats` for the resulting modifiers, through the same seam upgrades already use. |
| Personal builds per co-op player | Already true: `PlayerStats` is one instance per penguin and `RunWallet` is per player. Keep it that way. |
| Harvest as compounding wave-end economy | `PlayerStats.harvest_yield()` is the single place income is computed, and `RunProgression.finish_wave()` the single place a wave pays. Change those two, not the call sites. |
| Snow pickups as irregular blobs | `RunPickup` and its `_draw`. Presentation only; `RunPickup.Kind` stays. |
| Storm difficulty | `RunModifiers` resources in `resources/modifiers/`, chosen by `Expedition.modifiers`. |
| Horizontal unlocks | `CampaignState.unlocked` plus `CharacterDefinition.unlocked_by_default`. Prefer unlocking options over inflating stats. |

## Working alongside this branch

The architecture lane owns where the party is and what a room is. The gameplay
lane owns what happens in one.

**Safe to change for boss and content work**

- `scripts/bosses/**`, `resources/bosses/**`, boss scenes under `scenes/actors/`
- `scripts/data/boss_definition.gd` — adding content fields is expected
- `scripts/ui/boss_hud.gd` and other boss presentation
- `resources/encounters/*.tres` — including attaching a boss to a room
- `resources/modifiers/*.tres`, `resources/characters/*.tres`
- `tests/boss_*.gd`
- New `CharacterTrait` scenes and scripts

**Raise before changing — these are the contract**

- `scripts/encounters/encounter_director.gd`
- `scripts/actors/boss_actor.gd`, `scripts/actors/enemy.gd`
- `scripts/data/boss_schedule.gd`, `scripts/data/boss_tier.gd`
- `scripts/data/character_definition.gd`, `scripts/characters/character_trait.gd`

**Leave alone**

- `scripts/run/**` — `Expedition`, `RunSession`, `RunJournal`, `CampaignState`, `ProfileStore`
- `scripts/rooms/**` and `scripts/town/**`
- `scripts/data/room_definition.gd`, `room_exit.gd`, `cave_definition.gd`, `region_definition.gd`
- `scripts/arena/test_arena.gd`
- `scripts/ui/arena_hud.gd` and `scripts/ui/expedition_overlay.gd` — the HUD is
  being redesigned around the field shop; corner-card work is on hold
- `tests/seams_test.gd`, `tests/town_cave_test.gd`, `tests/stub_boss.gd`,
  `tests/stub_trait.gd` — these hold the contract

**Do not add**

A second thing that decides where the party is. `CaveJourney`,
`CaveDungeonDirector`, `DungeonFloorPlan` and any alternate town or cave owner
are all the same mistake: `Expedition` is the only authority, and room data is
the only description of a place.

## What this branch deliberately does not own

Bosses, new enemies, campaign balancing and content tuning belong to the
gameplay lane. The seams above are the supported way in; if something needs a
change to `Expedition`, `RoomDefinition` or `RunSession` to work, that is worth
raising rather than working around, because it usually means a seam is
missing.
