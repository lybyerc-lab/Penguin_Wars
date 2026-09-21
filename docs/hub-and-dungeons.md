# Penguin Wars: town and branching cave direction

Design direction from the September 21 conversation. A minimal playable staging area and cave-exit loop are now implemented; the services and branching exploration described below remain future work.

## Implemented travel loop

The final wave presents a centered Cave Cleared panel with Next cave and Back to town buttons for the shared local party. Town preserves the active run and provides a return entrance to the next cave. It is a safe staging area with decorative nurse, town hall and blacksmith buildings, not a completed town service simulation. The existing character-sheet stat shop works there.

`CaveJourney` owns cave depth, completion guards and transitions. `CaveTravelHUD` presents choices and arrival titles; `TownVisual` supplies the placeholder town. Players, their Resources and party IDs stay alive under the arena root during travel, preserving HP, stats, weapon bonuses, XP, level, wallets, paid price scaling, free choices and reserve income. Restart remains a fresh run; closing the app does not save the expedition. Downed players remain downed, pending a future revive/nurse design.

Room-local castles, supplies, health pickups and projectiles are cleared on travel. Remaining flakes are banked before cleanup. Each player can fund a new castle in the next cave; building is disabled in town. `RunProgression.begin_cave()` resets only wave-payment tracking and readiness; `ArenaLoot.begin_cave()` resets supply tracking. These hooks prevent skipped wave-one income and missing supplies on subsequent caves. The encounter definition is duplicated before adding a fresh seed and +2 base enemies per depth, capped at +20. Current caves share one arena layout and cycle three location names; route generation and unique dungeon geometry are not implemented.

Exit buttons move everyone together immediately. A future online host must validate the route and readiness/consensus policy. Introduce room scenes under a persistent session root when distinct cave maps replace the current composition.

## What stays central

Brotato-like combat, build variety and repeatable runs remain the core. A small penguin town gives those runs context. Caves branching off the town supply exploration through rooms, route choices, secrets and occasional simple puzzles. This avoids requiring a large overworld before the combat/build loop is proven.

## Proposed town loop

Town hall conversation → prepare in town → choose a cave entrance → combat rooms and branching routes → rewards/return → changed town conversation.

- **Shop:** supplies and run preparation.
- **Penguin nurse:** healing and recovery services. Costs and whether this restores a failed run's characters are still design decisions.
- **Penguin blacksmith:** weapon and armor upgrades. The split between permanent unlocks and temporary run power needs to be decided before adding persistence.
- **Town hall:** short, characterful meetings about penguin life, the current problems and what cave runs changed. These can provide objectives without interrupting combat.
- **Cave entrances:** visible side routes with different risks and rewards. A compact first dungeon can use one combat room, a branch between supplies and a harder encounter, and a final room.

## How the current systems carry forward

The town should own a session/party and transition into a dungeon run. Run wallets, player stats, loot and defenses currently reset with the arena and should become children of a run root. Individual rooms should own their encounter, spawn markers, exits, bounds and supply placements. An encounter completion signal can unlock the exit and open the upgrade phase.

PlayerStats is the initial seam for future skills. Harvest is implemented as a personal income multiplier, with fractional gains retained. A future skill system can modify these stats or grant actions without placing logic inside the HUD.

Snow castles are player-built supporting defenses in the current slice. They persist between waves, cost personal snowflakes and are capped at one per player per cave. They are cleared on travel, are not destructible, and enemies still target penguins. Engineering already increases their damage. Enemy targeting of castles and further castle upgrades remain later decisions.

## Economy implemented now

- Snowflakes are run materials: gathering them gives XP and currency.
- Shared pickup value is distributed round-robin among living party members; each keeps a personal wallet and shops independently.
- XP grants free stat choices; currency buys additional stat upgrades between waves.
- Uncollected flakes enter a shared reserve, released as matching bonus value on later pickups.
- Each cleared wave grants five base income per living player, scaled by Harvest.
- Harvest starts at x1.00; each upgrade adds +0.25. It affects personal pickup allocation and wave income, carrying fractional amounts forward.

This follows the material/XP/between-wave-shop loop described on [Brotato's official Steam page](https://store.steampowered.com/app/1942280/Brotato/). The requested Harvest multiplier and deterministic co-op split are Penguin Wars choices, not claims of exact Brotato parity. Armor and other combat stats are implemented. Randomized shop stock, rerolls, inventory, weapon merging and a full skill system are not implemented yet.
