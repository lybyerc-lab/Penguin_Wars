# Penguin Wars

A Godot 4.7 foundation for a 1–4 player, top-down co-op action roguelite. Open `project.godot` and press **F6** on the test arena or **F5** to run the project. No plugins, external assets, or dependencies are required.

## Play the test arena

- Player 1: **WASD**, **Space** dash, **Q / E / T** damage/speed/Harvest upgrades, **B** build castle, **F** ready for next wave.
- Player 2: **Arrow keys**, **Ctrl** dash, **Enter / Shift / Period** upgrades, **N** build castle, **Slash (/)** ready.
- Each assigned gamepad: **left stick**, **X** dash, **A / B / right bumper** upgrades, **Y** build castle, **Start** ready.
- Attacks automatically strike the nearest enemy within weapon range.
- **R** restarts the run, including after victory or a party wipe.
- Select your color-matched penguin card in a screen corner to open stats, upgrades, castle building, ready-up and restart controls. Keyboard/gamepad shortcuts remain available. Upgrades are chosen in the between-wave shop; all living players must ready up before the next wave.

### Supplies, snowflakes and defenses

Two breakable snowmen supply the arena. Weapons prioritize enemies, then target snowmen in range; cleaver sweeps can hit both. Each snowman drops a **25 HP** pickup and **3 snowflakes**. Full-health players leave healing on the ground. Missing snowmen return at the next wave; intact ones remain.

Enemy defeats drop **2 snowflakes** rather than immediately granting XP. Either player can collect a drop; its units are split round-robin among living players into **personal wallets**, also awarding XP. Uncollected snowflakes enter the run's reserve after a wave and add matching bonus value to future pickups. Downed players receive no allocation. Wallets and reserves reset with the run.

**Harvest** starts at x1.00 and upgrades by +0.25. It multiplies that player's income and corresponding XP, including the **5 base income** paid after each completed wave. Fractional earnings are retained so small drops still benefit. This multiplier is our chosen variation, not an exact copy of Brotato's flat harvesting stat.

XP still grants free stat choices. Extra upgrades cost **6 snowflakes**, increasing by **3 per personal paid purchase**. Shopping happens between waves; a purchase clears that player's ready status. The character sheet now offers 15 upgrades, including armor, regeneration, typed damage, critical hits, dodge, Engineering and Harvest. The original three remain quick shortcuts. Randomized items, rerolls, weapon merging and a full skill system are future work.

### Android and character stats

Select a **corner penguin card** to open the character sheet. Cards show matching team scarves, health bars, level and personal flakes. P1/P2 occupy the upper corners; P3/P4 occupy the lower corners when present. The playable floor fills the viewport, and a centered location banner fades away after arrival. Preview the phone layout with `godot --path . -- --mobile` or enable `TestArena.mobile_preview` in the inspector. Android automatically selects one local penguin and touch movement/dash. The solo mobile character sheet pauses combat. Desktop co-op remains available; online co-op is future work.

The Android debug APK now builds and passes signing/alignment checks. Find it locally at `builds/penguin-wars-debug.apk`. **Physical phone testing remains pending.** Rebuild on this PC with `./tools/build-android.ps1 -WorkspaceToolchain`. See [mobile-and-stats.md](docs/mobile-and-stats.md) for stat formulas, extension points, preview controls and export setup.

**Snow castles are player-built defenses.** Spend **10 personal snowflakes** to place one on open ice in front of your penguin. Each player can build one per cave. It fires friendly snowballs for **8 base damage every 0.9 seconds**, plus Engineering, with **275-pixel targeting range**, and never damages teammates. Invalid placements spend nothing. Castles persist between waves but stay behind when leaving a cave; they are currently indestructible support structures, with enemies continuing to target penguins.

### Cave exits and town

Finish the final wave to see **CAVE CLEARED!**, then choose **Next cave** or **Back to town**. Either choice moves the whole local party. You can open your penguin card to spend rewards before leaving. The exit choices stay available until selected; on mobile they replace the automatic end-of-cave shop screen.

The next cave starts at wave one and keeps each player's health, stats, weapon bonuses, XP, level, flakes and pending upgrades. It uses a fresh seed and two more base enemies per depth (capped at +20); current caves reuse the same combat floor. Returning to the peaceful **Frostfall Town** staging area preserves the same run, allows stat shopping, and provides **Enter cave N** to continue. No automatic full heal or revival is granted; regeneration still works. Restart still begins a fresh run.

Stationary castles, health drops, supplies and projectiles do not travel. Uncollected flakes are banked in the existing reserve. The nurse, blacksmith and town hall are labeled placeholders; their services, stories and branching dungeon layouts remain future work. See [hub-and-dungeons.md](docs/hub-and-dungeons.md).

### Boss milestones and ending

After the normal waves, caves **5 and 15** add Frostbreaker mini-bosses, cave **10** adds Glacier Warden, and cave **20** adds **Mondo, the War King**. Bosses have a shared health display, telegraphed attacks and co-op health scaling. Exits unlock only after the boss dies.

Defeating Mondo at cave 20 offers **End the war** (victory and peaceful town) or **Endless caves** (keep the build and continue to cave 21). Endless repeats the 20-cave boss cycle with increasing enemy health and damage. See [bosses-and-endless.md](docs/bosses-and-endless.md) for attack patterns, tuning and extension points.

### Weapons and movement

P1 (and P3) carries the **Ice Lance**: a fast single-target strike with 240-pixel range, 14 damage and a 0.42-second cooldown. P2 (and P4) carries the **Fish Cleaver**: a 140-degree sweep that damages every enemy in its 105-pixel reach for 22 damage, with a 1.05-second cooldown and stronger knockback. Both aim automatically at the nearest enemy. These are initial tuning values, not final balance.

Dashes travel at 680 pixels/second for 0.16 seconds and grant invulnerability during that burst. The 1.1-second cooldown starts when the dash begins. Move to set direction, or dash along the last movement direction when stationary. Holding the button does not repeat dashes. The HUD shows each player's weapon and dash readiness. Hit flashes, floating damage, expanding impact rings, dash trails and cleaver arcs make combat events visible. No global hit pause or camera shake disrupts the other player's view.

### Enemy roles

- **Seal raider:** the original pursuing contact enemy.
- **Charging seal:** orange armored brow, 44 HP. Marks an orange lane for 0.75 seconds, rushes straight along that lane, then recovers for 1.1 seconds with contact damage disabled. Step sideways or dash across the lane, then punish its recovery. Introduced as the third spawn in wave 1.
- **Snowball thrower:** blue winter cap and visible snowball, 28 HP. Maintains distance, marks its locked aim with a dotted line for 0.7 seconds, then fires a non-homing snowball. Snowballs deal 10 damage, hit at most one player, and expire after three seconds. Close the gap to force it to retreat. Introduced in wave 2.

The cleaver's strong knockback interrupts charger windups/rushes and thrower windups. The lance still pushes enemies but does not interrupt these attacks. Dash immunity blocks a snowball and consumes that shot. Enemy counts and the existing dash/weapon tuning are unchanged; mixed roles make positioning more important. These are initial encounter balance values for playtesting.

Three seeded encounters scale enemy count with party size. Collected materials and end-of-wave income grant XP; each player chooses upgrades independently. Downed players stop moving/attacking and are excluded from enemy targeting. Revival is not implemented. The arena uses original illustrated SVG penguins, seal raiders and visible held weapons, with a procedural ice-island backdrop.

Set `TestArena.player_count` in the inspector to 1–4. Slots 1 and 2 have keyboard controls; slots 3 and 4 require gamepads. Slot indices map directly to Godot device IDs 0–3; a lobby/device assignment screen is a future extension. Keyboard and gamepad can control the same assigned slot. Physical keyboard bindings are intentionally fixed for this test scene.

## Structure

| Location | Responsibility |
| --- | --- |
| `scenes/actors` | Reusable player and enemy scenes |
| `scripts/actors` | Character motion and enemy behavior |
| `scripts/party` | Stable player identity and party queries |
| `scripts/input` | Local movement input adapter |
| `scripts/combat` | Health, damage messages, weapon runtime |
| `scripts/progression` | Per-player XP and run reward/choice policy |
| `scripts/loot`, `scenes/props` | Breakable snowmen, health/material pickups and wave resupply |
| `scripts/defenses` | Player-funded castle placement and friendly projectiles |
| `scripts/data`, `resources` | Typed weapon, upgrade and encounter definitions |
| `scripts/encounters` | Seeded spawn and encounter state machine |
| `scripts/enemies` | Replaceable charge/ranged behaviors and enemy snowballs |
| `scripts/camera`, `scripts/ui` | Shared view and test HUD |
| `scripts/arena` | Small composition root |
| `scripts/journey` | Cave completion, party travel and preservation of the current run |
| `scripts/visuals`, `assets` | Character animation, held weapons, illustrated SVGs and ice arena art |
| `tests` | Engine integration and renderer smoke tests |

## Extension points and boundaries

**Party and networking.** `PlayerIdentity.player_id` is a unique run slot (1–4). `owner_peer_id` is a separate future connection mapping; multiple local slots may share the same peer. `PartyRoster` is session-owned and rejects duplicate IDs. There are no global singleton player references. This is playable local co-op, **not online multiplayer**: there are no RPCs, authority enforcement, replicated spawns, prediction, reconnect, or serialization yet. Before online play, introduce a host-owned simulation, validated input commands, stable enemy IDs and authoritative rewards; route all actor spawning, damage and upgrade choices through it. The seed makes spawn selection repeatable for the same simulation state, not lockstep deterministic.

**Input.** The player consumes `LocalPlayerInput.movement()`. Replace that adapter with remappable actions, recorded commands, or network commands. Move ownership checks to the future session layer. Gamepads have a radial dead zone. Hot-plug lobby assignment and physical controller testing remain future work.

**Damage.** `Health.take_damage(DamageEvent)` is the shared damage interface; `changed`, `damaged` and `died` are the output hooks. Damage events retain the source party ID and a knockback impulse. Dead actors reject further damage and healing; use a separate explicit revive operation later. `HitFeedback` listens to accepted damage and creates short-lived world effects which survive enemy deletion. `DashController` owns per-player burst/cooldown state; the player applies its motion and invulnerability. Weapons currently use instantaneous single-target or arc attacks. Add projectile scenes, teams and status effects around these interfaces. Before adding other immunity sources, replace the single invulnerability flag with a composed immunity policy.

**Data.** Add `.tres` resources using `WeaponDefinition`, `UpgradeDefinition`, or `EncounterDefinition`. Shared resources are definitions and must remain immutable during play. Runtime cooldowns and damage bonuses belong to each weapon instance. `PenguinPlayer.apply_upgrade()` is the initial stat application seam; move into a dedicated stat aggregator when stacking rules grow. `RunProgression.OPTIONS` is the test catalog, ready to replace with weighted offers and unlock filters.

**Visuals.** `CharacterVisual` creates character sprites, team scarves and cosmetic movement bobbing. `WeaponVisual` reads the weapon's presentation aim/attack phase to place its art beside the player and animate a thrust or sweep. Each weapon Resource supplies `held_texture` and `visual_scale`; add right-facing art with its handle on the left. Damage timing remains in `WeaponController`, independent of sprite motion. Idle weapons face the player's last movement direction; in-range targets drive aim between attacks. Attack tracers retain their actual impact position. `IceArenaVisual` draws seeded ice across the whole viewport. Corner HUD cards overlay the floor, and the location banner fades after arrival. All assets in `assets/` were authored for this project; no Brotato assets were imported.

**Encounters.** `EncounterDirector` emits state changes, kill events and completion. Spawn placement currently assumes this centered bounded arena and chooses the safest perimeter candidate. Replace this method with region spawn markers/navigation for real maps. Enemy movement is direct pursuit with world collision support, not pathfinding. Actors do not block one another. External despawns need an explicit director cancellation/despawn path so enemy counts remain correct.

**Enemy behavior.** `ArenaEnemy` remains the shared health, contact and knockback actor. Optional `EnemyBehavior` children supply movement and attack state; inherited charger/thrower scenes configure those strategies. `EnemyAttackVisual` reads state to display warnings without controlling damage. New encounter Resource fields select the charger and ranged scenes; the director owns their introduction cadence. `EnemySnowball` uses swept segment hits against living party members and a layer-1 world ray, with no friendly fire. Shots can outlive their shooter but are cleared at wave completion or party wipe and freed with the run. Actor clamping and projectile limits share the current arena room bounds; move the resize policy into dungeon room data when exploration lands.

**Exploration and camera.** The camera holds a fixed full-screen room view. Players and enemies share viewport-sized bounds with a small body inset; the room updates when the window size changes. For Zelda-style rooms, introduce a region/room scene owning bounds, spawn markers, exits and encounters; gate exits on `completed`. Decide party tethering and room transitions before permitting independent exploration. No split-screen is implemented.

**Progression.** `Experience` handles XP overflow and emits one event per level; `RunProgression` owns team reward policy and queued personal choices. Downed players receive no XP. A new arena instance starts a fresh run. Boss milestones and campaign/endless flow are implemented. Save data, unlocks, inventory, interaction and branching route selection remain future layers.

**Economy and skills seam.** `PlayerStats` is a unique Resource instance per player and owns the Harvest multiplier/fractional carry. `RunWallet` owns balances; `RunProgression` owns material allocation, wave payments, purchases and readiness. `ArenaLoot` owns supply placement, drop wiring and reserve banking. `RunPickup` prevents duplicate collection and wasted healing. Breakable weapon targets expose a `Health` child and join `breakables`; enemy targets remain higher priority. `CastleBuilder` validates ownership, placement and affordability before spending. A future skill layer can grant stat modifiers or abilities through these separate systems. Move arena-specific bounds and prop locations into room data before introducing dungeons.

## Verification

From this directory, with `godot` available:

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/foundation_test.gd
godot --headless --path . --script res://tests/combat_feel_test.gd
godot --headless --path . --script res://tests/enemy_behavior_test.gd
godot --headless --path . --script res://tests/economy_test.gd
godot --headless --path . --script res://tests/stats_mobile_test.gd
godot --headless --path . --script res://tests/fullscreen_hud_test.gd
godot --headless --path . --script res://tests/cave_journey_test.gd
godot --headless --path . --script res://tests/boss_campaign_test.gd
godot --path . --script res://tests/render_smoke.gd
godot --path . --script res://tests/enemy_render_smoke.gd
godot --path . --script res://tests/economy_render_smoke.gd
godot --path . --script res://tests/mobile_render_smoke.gd
godot --path . --script res://tests/mobile_render_smoke.gd -- --wide
godot --path . --script res://tests/cave_journey_render.gd
godot --path . --script res://tests/cave_journey_render.gd -- --mobile
godot --path . --script res://tests/boss_render_smoke.gd
```

The integration test fails with a nonzero exit code on failed assertions. It covers party IDs/capacity, movement/bounds, death/retargeting, XP overflow, queued upgrades and resource isolation, actual weapon kills/rewards, encounter completion, party wipe and scene cleanup. The renderer test writes `docs/arena-preview.png` using the live viewport. See `docs/verification.md` for actual results and limitations.

The combat test checks dash speed, immunity windows, cooldown, death gating and player isolation; cleaver multi-target coverage, rear/range exclusions and knockback; weapon cooldown and long-range single-target lance behavior. The renderer test includes a controlled combat pose to inspect effects reliably. Physical input and subjective combat feel still need human playtesting.
