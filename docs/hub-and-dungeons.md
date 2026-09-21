# Penguin Wars: town and branching cave direction

Design direction from the September 21 conversation. The town, the services and the first branching cave are now built in `scenes/run/expedition.tscn`; this note records what the direction asked for, what was delivered, and what it deliberately left open.

## What is built

- **Kelphollow**, with the shop, nurse, blacksmith and town hall as positional zones. No new input bindings: the wave-shop keys pick service offers while a penguin stands in a zone.
- **The Hollow Shelf**, a four-room cave with one branch — a quiet supply seam against a louder gallery — that rejoins at a final room and leads home.
- **Room-owned space.** `RoomDefinition` supplies bounds, spawn ring, supply points, entry point, palette, encounter and exits; `RoomSpace.apply()` hands them to the party, director, builder, loot, camera and backdrop. `RoomExit` targets a room by id and `CaveDefinition` owns the route graph.
- **A run root.** `Expedition` keeps wallets, stats, levels and purchases across a room change; the room's own actors go with the room. `RunSession` holds the wiring the arena slice uses too.
- **Revival**, as the nurse's service, through a `Health.revive()` operation separate from healing.
- **A run journal**, so the town hall meeting changes once the party has been down a cave.
- **A boss** at the end of the cave, with telegraphed attacks, knockback resistance and a reward paid to every living penguin. Ranks two and three exist as data and are not placed yet.
- **A room difficulty dial**, so the loud branch is genuinely harder than the quiet one without a second set of enemy scenes.

## What is still open

- Persistence. The journal, wallets and stats reset with the run; save data and unlocks between runs do not exist.
- The permanent-versus-temporary split for the blacksmith. Everything it sells is currently run power only.
- Touch. Service panels are keyboard and gamepad only; the Android layout still covers the arena slice.
- Room geometry. Bounds are a rectangle with no interior collision, so no doors, walls or irregular rooms.
- More caves, secrets and puzzles. One cave exists and its layout table lives in code, not data, because one town exists. The Glacier Warden and Mondo are written but have no room to stand in.
- A shared HUD decision. The Antigravity branch reworks the heads-up display into four corner cards with a click-to-open character sheet, which frees the top of the screen that the current card grid occupies. That is a presentation choice, not a correctness one, so it was left alone here rather than merged; it is worth deciding deliberately.
- Balance. Every price, revival fraction and encounter value is a first pass for playtesting.

## What stays central

Brotato-like combat, build variety and repeatable runs remain the core. A small penguin town gives those runs context. Caves branching off the town supply exploration through rooms, route choices, secrets and occasional simple puzzles. This avoids requiring a large overworld before the combat/build loop is proven.

## The town loop

Town hall conversation → prepare in town → choose a cave entrance → combat rooms and branching routes → rewards/return → changed town conversation. This is the loop the expedition scene now runs.

- **Shop** — *Fisher's Stall.* Rations, maximum health and a Harvest charm.
- **Penguin nurse** — *Nurse's Hut.* Mending, a regeneration tonic, and rousing a downed penguin at 40% health for 14 snowflakes. A downed penguin cannot pay for its own revival. A total party wipe still ends the run; nothing restores a failed run's characters.
- **Penguin blacksmith** — *Cold Forge.* Weapon damage, attack speed and trading lance for cleaver. Everything it sells is run power; the permanent-unlock split is still undecided, which is why nothing here persists.
- **Town hall** — *Elder Bramblefoot.* A short meeting that reads the run journal, so the elder says something different before and after a cave. It never interrupts combat, because there is none in town.
- **Cave entrances.** One so far: the Hollow Shelf, as an entrance fight, a branch between supplies and a harder encounter, and a final room.

## How the current systems carry forward

The town owns the session and transitions into a cave run. Run wallets, player stats, loot and defences are now children of the `Expedition` run root rather than resetting with an arena, and each room owns its encounter, spawn ring, exits, bounds and supply placements. The director's `completed` signal unlocks the room's routes. Castles are room-scoped: a castle belongs to the room it was built in, and its owner may build again in the next one — whether defences should persist across rooms is still undecided.

PlayerStats is the initial seam for future skills. Harvest is implemented as a personal income multiplier, with fractional gains retained. A future skill system can modify these stats or grant actions without placing logic inside the HUD.

Snow castles are player-built supporting defences. They cost personal snowflakes and are capped at one per player at a time. They are not destructible and enemies still target penguins. Enemy targeting of castles, upgrading them and a dedicated engineering stat are later decisions.

## Economy implemented now

- Snowflakes are run materials: gathering them gives XP and currency.
- Shared pickup value is distributed round-robin among living party members; each keeps a personal wallet and shops independently.
- XP grants free stat choices; currency buys additional stat upgrades between waves.
- Uncollected flakes enter a shared reserve, released as matching bonus value on later pickups.
- Each cleared wave grants five base income per living player, scaled by Harvest.
- Harvest starts at x1.00; each upgrade adds +0.25. It affects personal pickup allocation and wave income, carrying fractional amounts forward.

This follows the material/XP/between-wave-shop loop described on [Brotato's official Steam page](https://store.steampowered.com/app/1942280/Brotato/). The requested Harvest multiplier and deterministic co-op split are Penguin Wars choices, not claims of exact Brotato parity. Randomized shop stock, rerolls, inventory, weapon merging, armor and a full skill system are not implemented yet.
