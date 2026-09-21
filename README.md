# Penguin Wars

A Godot 4.7 foundation for a 1–4 player, top-down co-op action roguelite. Open `project.godot` and press **F6** on the test arena or **F5** to run the project. No plugins, external assets, or dependencies are required.

## Play the test arena

- Player 1: **WASD**, **Space** to dash, **Q / E** to spend level-up choices.
- Player 2: **Arrow keys**, **Ctrl** to dash, **Enter / Shift** to spend choices.
- Each assigned gamepad: **left stick**, **X** to dash, **A / B** to spend choices.
- Attacks automatically strike the nearest enemy within weapon range.
- **R** restarts the run, including after victory or a party wipe.
- Upgrade buttons can also be clicked. Choices queue without pausing other players.

### Combat slice

P1 (and P3) carries the **Ice Lance**: a fast single-target strike with 240-pixel range, 14 damage and a 0.42-second cooldown. P2 (and P4) carries the **Fish Cleaver**: a 140-degree sweep that damages every enemy in its 105-pixel reach for 22 damage, with a 1.05-second cooldown and stronger knockback. Both aim automatically at the nearest enemy. These are initial tuning values, not final balance.

Dashes travel at 680 pixels/second for 0.16 seconds and grant invulnerability during that burst. The 1.1-second cooldown starts when the dash begins. Move to set direction, or dash along the last movement direction when stationary. Holding the button does not repeat dashes. The HUD shows each player's weapon and dash readiness. Hit flashes, floating damage, expanding impact rings, dash trails and cleaver arcs make combat events visible. No global hit pause or camera shake disrupts the other player's view.

### Enemy roles

- **Seal raider:** the original pursuing contact enemy.
- **Charging seal:** orange armored brow, 44 HP. Marks an orange lane for 0.75 seconds, rushes straight along that lane, then recovers for 1.1 seconds with contact damage disabled. Step sideways or dash across the lane, then punish its recovery. Introduced as the third spawn in wave 1.
- **Snowball thrower:** blue winter cap and visible snowball, 28 HP. Maintains distance, marks its locked aim with a dotted line for 0.7 seconds, then fires a non-homing snowball. Snowballs deal 10 damage, hit at most one player, and expire after three seconds. Close the gap to force it to retreat. Introduced in wave 2.

The cleaver's strong knockback interrupts charger windups/rushes and thrower windups. The lance still pushes enemies but does not interrupt these attacks. Dash immunity blocks a snowball and consumes that shot. Enemy counts and the existing dash/weapon tuning are unchanged; mixed roles make positioning more important. These are initial encounter balance values for playtesting.

Three seeded encounters scale enemy count with party size. Kills give all living players XP; each player chooses damage or movement upgrades independently. Downed players stop moving/attacking and are excluded from enemy targeting. Revival is not implemented. The arena uses original illustrated SVG penguins, seal raiders and visible held weapons, with a procedural ice-island backdrop.

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
| `scripts/data`, `resources` | Typed weapon, upgrade and encounter definitions |
| `scripts/encounters` | Seeded spawn and encounter state machine |
| `scripts/enemies` | Replaceable charge/ranged behaviors and enemy snowballs |
| `scripts/camera`, `scripts/ui` | Shared view and test HUD |
| `scripts/arena` | Small composition root |
| `scripts/visuals`, `assets` | Character animation, held weapons, illustrated SVGs and ice arena art |
| `tests` | Engine integration and renderer smoke tests |

## Extension points and boundaries

**Party and networking.** `PlayerIdentity.player_id` is a unique run slot (1–4). `owner_peer_id` is a separate future connection mapping; multiple local slots may share the same peer. `PartyRoster` is session-owned and rejects duplicate IDs. There are no global singleton player references. This is playable local co-op, **not online multiplayer**: there are no RPCs, authority enforcement, replicated spawns, prediction, reconnect, or serialization yet. Before online play, introduce a host-owned simulation, validated input commands, stable enemy IDs and authoritative rewards; route all actor spawning, damage and upgrade choices through it. The seed makes spawn selection repeatable for the same simulation state, not lockstep deterministic.

**Input.** The player consumes `LocalPlayerInput.movement()`. Replace that adapter with remappable actions, recorded commands, or network commands. Move ownership checks to the future session layer. Gamepads have a radial dead zone. Hot-plug lobby assignment and physical controller testing remain future work.

**Damage.** `Health.take_damage(DamageEvent)` is the shared damage interface; `changed`, `damaged` and `died` are the output hooks. Damage events retain the source party ID and a knockback impulse. Dead actors reject further damage and healing; use a separate explicit revive operation later. `HitFeedback` listens to accepted damage and creates short-lived world effects which survive enemy deletion. `DashController` owns per-player burst/cooldown state; the player applies its motion and invulnerability. Weapons currently use instantaneous single-target or arc attacks. Add projectile scenes, teams and status effects around these interfaces. Before adding other immunity sources, replace the single invulnerability flag with a composed immunity policy.

**Data.** Add `.tres` resources using `WeaponDefinition`, `UpgradeDefinition`, or `EncounterDefinition`. Shared resources are definitions and must remain immutable during play. Runtime cooldowns and damage bonuses belong to each weapon instance. `PenguinPlayer.apply_upgrade()` is the initial stat application seam; move into a dedicated stat aggregator when stacking rules grow. `RunProgression.OPTIONS` is the test catalog, ready to replace with weighted offers and unlock filters.

**Visuals.** `CharacterVisual` creates character sprites, team scarves and cosmetic movement bobbing. `WeaponVisual` reads the weapon's presentation aim/attack phase to place its art beside the player and animate a thrust or sweep. Each weapon Resource supplies `held_texture` and `visual_scale`; add right-facing art with its handle on the left. Damage timing remains in `WeaponController`, independent of sprite motion. Idle weapons face the player's last movement direction; in-range targets drive aim between attacks. Attack tracers retain their actual impact position. `IceArenaVisual` owns purely decorative seeded ice, crystals and snow; these props do not block movement. The camera reserves top/bottom HUD space and expands that allowance for a four-player party. All assets in `assets/` were authored for this project; no Brotato assets were imported.

**Encounters.** `EncounterDirector` emits state changes, kill events and completion. Spawn placement currently assumes this centered bounded arena and chooses the safest perimeter candidate. Replace this method with region spawn markers/navigation for real maps. Enemy movement is direct pursuit with world collision support, not pathfinding. Actors do not block one another. External despawns need an explicit director cancellation/despawn path so enemy counts remain correct.

**Enemy behavior.** `ArenaEnemy` remains the shared health, contact and knockback actor. Optional `EnemyBehavior` children supply movement and attack state; inherited charger/thrower scenes configure those strategies. `EnemyAttackVisual` reads state to display warnings without controlling damage. New encounter Resource fields select the charger and ranged scenes; the director owns their introduction cadence. `EnemySnowball` uses swept segment hits against living party members and a layer-1 world ray, with no friendly fire. Shots can outlive their shooter but are cleared at wave completion or party wipe and freed with the run. Current arena clamping and projectile bounds must move to room-owned bounds when exploration lands.

**Exploration and camera.** The camera frames the bounded arena and living party, with margin and smoothing. Players are clamped to this arena. For Zelda-style rooms, introduce a region/room scene owning bounds, spawn markers, exits and encounters; gate exits on `completed`. Decide party tethering and room transitions before permitting independent exploration. No split-screen is implemented.

**Progression.** `Experience` handles XP overflow and emits one event per level; `RunProgression` owns team reward policy and queued personal choices. Downed players receive no XP. A new arena instance starts a fresh run. Save data, unlocks, inventory, bosses, interaction and run route selection are deliberately left to subsequent layers.

## Verification

From this directory, with `godot` available:

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/foundation_test.gd
godot --headless --path . --script res://tests/combat_feel_test.gd
godot --headless --path . --script res://tests/enemy_behavior_test.gd
godot --path . --script res://tests/render_smoke.gd
godot --path . --script res://tests/enemy_render_smoke.gd
```

The integration test fails with a nonzero exit code on failed assertions. It covers party IDs/capacity, movement/bounds, death/retargeting, XP overflow, queued upgrades and resource isolation, actual weapon kills/rewards, encounter completion, party wipe and scene cleanup. The renderer test writes `docs/arena-preview.png` using the live viewport. See `docs/verification.md` for actual results and limitations.

The combat test checks dash speed, immunity windows, cooldown, death gating and player isolation; cleaver multi-target coverage, rear/range exclusions and knockback; weapon cooldown and long-range single-target lance behavior. The renderer test includes a controlled combat pose to inspect effects reliably. Physical input and subjective combat feel still need human playtesting.
