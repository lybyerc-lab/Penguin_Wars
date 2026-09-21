# Verification record

## Adventure foundation hardened into seams

September 21, 2026: verified in a Linux container with Godot **4.7.2 stable**, compatibility rendering, OpenGL through Xvfb.

This pass makes the room and run architecture the source of truth and gives other work defined places to plug into. `architecture.md` states the contract and every extension point.

**Boss content was removed from this branch, on purpose.** The previous pass merged the Antigravity boss implementation here; bosses belong to the gameplay lane, and two implementations of the same feature is the problem this split exists to avoid. What remains is the phase and its contract: `EncounterDefinition.boss` is optional, the director runs a boss phase after the final wave, the room's exits stay shut until the boss falls, and `BossActor` is the class boss content subclasses. The director reads exactly three fields from `BossDefinition` — `scene`, `display_name`, `reward` — so new boss content needs no director change. The removed content remains on the `antigravity` branch and at commit 0663092.

Seams added, each an interface or a small data resource rather than the feature behind it:

- **Run modifiers.** `RunModifiers` holds whole-run dials and composes with, rather than replaces, `EncounterDefinition.difficulty_multiplier`. The identity default means a run that names none behaves exactly as before.
- **Character selection.** `CharacterDefinition` plus `RunSession.roster`. The default roster reproduces the original four penguins exactly — the resources were generated through Godot so the tints round-trip bit-for-bit rather than being hand-written floats.
- **Campaign and milestones.** `CampaignState` for what outlives a run; `RunJournal` stays run-scoped and reports into it.
- **Save and permanent unlocks.** `ProfileStore`, whose default holds state in memory and reports `is_persistent()` false, so nothing promises a save that does not exist.
- **Regions.** `RegionDefinition` replaces `Expedition`'s town and cave constants, so a second cave is a list entry and a second region is a resource.

- Seven headless suites passed with zero failures: foundation, combat feel, enemy behavior, economy, stats/mobile, town/cave and the new seam suite. Six render runs passed: arena, enemy, economy, mobile normal and wide, and town.
- `seams_test.gd` drives the boss phase with `tests/stub_boss.gd`, a boss with no attacks, art or telegraphs, so the contract is verified without this branch owning boss content. It checks that `configure()` runs once, with the party size, before the node enters the tree where Health takes current from maximum; that run and room scaling compose and are applied to a boss identically to any other enemy; that `boss_started` announces once and the reward reaches every living penguin and cannot be claimed twice; and that a boss whose scene is missing completes the room rather than stranding the party. It was negative-controlled: altering the expected scaled health and the reward assertion produced two failures and a nonzero exit.
- Two defects were found and fixed while writing that suite: assigning an untyped array to a typed `Array[CharacterDefinition]` export failed at runtime, and hand-written colour floats in the character resources did not compare equal to `Color(hex)`.

Limitations: no human playthrough of this pass. The seams are exercised programmatically, which proves the contracts hold, not that the features built on them will feel right. `ProfileStore` does no file I/O by design, so save durability is untested because there is nothing yet to test. No room ships with a boss, so the phase is proven only against the stub. Android packaging was not re-run; the arena slice remains the main scene.

## Boss phase and enemy data, merged from the Antigravity branch

September 21, 2026: verified in a Linux container with Godot **4.7.2 stable**, compatibility rendering, OpenGL through Xvfb.

The Antigravity branch built the town and caves independently and also added a boss system, a heads-up display rework and several smaller changes. Its town and cave implementation was not merged, because an equivalent already exists here and running both would leave two answers to the same question. What was taken is what this branch did not have.

- **Two real defects it caught.** A snow castle could be bought and placed in the town square, and a free level-up choice earned underground could not be spent until the next room's intermission, because town has no encounter state. Both now have regression checks in the town and cave suite; reverting either fix turns four checks red, which was confirmed rather than assumed.
- **Per-enemy combat data.** `contact_radius`, `hit_radius`, `projectile_damage` and `knockback_multiplier` replace shared constants, and a thrower's shot now carries its own shooter's damage. This is what makes a boss a larger, steadier target without a second combat path.
- **The boss phase.** `BossDefinition`, `ArenaBoss`, `BossBehavior`, the boss scene, three boss resources and the boss bar, adapted to this branch's room-owned spawn ring and placed through room data — the mini-boss stands at the end of the Black Ledge — rather than through the Antigravity endless-cave schedule, which does not fit a named cave.
- **Room difficulty and an arrival banner.** `EncounterDefinition.difficulty_multiplier` makes the Cracked Gallery branch genuinely harder at 1.25. The banner was repositioned out of the play area, since a room's fight can start the moment the party arrives.

- Seven headless suites passed with zero failures: foundation, combat feel, enemy behavior, economy, stats/mobile, town/cave and the new boss suite. Seven render runs passed: arena, enemy, economy, mobile normal and wide, town and the new boss run.
- `boss_test.gd` walks the real cave to the Black Ledge and checks that the boss follows the final wave rather than replacing it, health scaling with party size, routes staying shut while it lives, each telegraph being harmless and direction-locked, a heavy hit failing to cancel a windup, contact landing only during the rush, difficulty scaling applied before health is taken from maximum, and the reward being paid once to every living penguin and not twice. It was negative-controlled: altering the expected boss health produced a failure and a nonzero exit.
- `cave-boss.png` was written from the live viewport and inspected for the crown, the ring, the drawn charge lane and the boss bar with its damage.

Not merged: the corner-card heads-up display rework and its character-sheet buttons, the Antigravity town, cave, dungeon and journey scripts, and its flattened arena backdrop. The display rework is a deliberate presentation choice and is recorded as an open decision in hub-and-dungeons.md.

Limitations: no human playthrough of a boss fight. The boss is driven through its states programmatically, which proves the telegraph contract and the reward path, not whether the fight is fun or fairly tuned. Boss health, damage, the +65% party scaling and the 1.25 branch multiplier are all first values. Ranks two and three are exercised only through their data.

## Town, services and the first branching cave

September 21, 2026: verified in a Linux container with Godot **4.7.2 stable**, compatibility rendering, OpenGL through Xvfb. This is the first run of the suites outside Windows; all previously recorded results reproduced.

- Six headless integration suites passed with zero failures: foundation, combat feel, enemy behavior, economy, stats/mobile, and the new town/cave suite. The five pre-existing suites were run before and after each change in this work, including the move of arena bounds into room data and the move of the arena onto the shared `RunSession` wiring.
- `town_cave_test.gd` walks the real expedition scene end to end: cave route resolution and the empty-cave case, town composition, per-room bounds and spawn rings, every service purchase and each refusal path (empty wallet, unknown offer, full health, a downed penguin trading for itself, nobody to rouse), revival and the collision layers it restores, the locked-route rule, a supply room stocking without a wave, prop and wallet behaviour across a transition, the journal, and leak checks on teardown. The harness was negative-controlled: an intentionally false check produced a failure and a nonzero exit.
- Five OpenGL render runs passed: arena, enemy, economy, mobile (normal and wide) and the new town run. `town-preview.png`, `cave-entrance.png`, `cave-branch.png` and `cave-supply-room.png` were written from the live viewport and visually inspected for building art and labels, service panels with their keys and costs, the town-hall meeting text, locked and unlocked route captions, the party-count prompt, room palettes and per-room framing.
- The rendered arena is unchanged by the bounds refactor: `arena-preview.png` was regenerated, compared against the committed image and reverted, since the backdrop now derives the same shapes from the room bounds.
- Two presentation defects were found by inspecting those screenshots and fixed: route captions were clipped to the pad width, and town building labels sat under the penguins standing at them.

Limitations: no human playthrough. Travel and room clearing are driven programmatically in both new suites, which proves the transition wiring and the gate rule, not pacing or balance. Every price, the 40% revival fraction and the three new encounter definitions are first values. Service panels have no touch controls, so the town is keyboard and gamepad only. Android packaging was not re-run in this environment; the arena slice remains the project's main scene and the exported one.

## Android APK build resolved

September 21, 2026: installed portable Java 17 and Android SDK build packages, configured normal/workspace Godot paths, generated a local debug key, enabled ETC2/ASTC imports, added a penguin launcher icon, and explicitly selected Compatibility for the mobile renderer. SDK 36 matches the actual installed Godot 4.7.2 template (the general export guide listed older package versions).

- `tools/build-android.ps1 -WorkspaceToolchain`: successful import and debug APK export, exit 0.
- Independent `apksigner verify`: v2 and v3 signatures passed. `zipalign -c -P 16 4`: exit 0.
- Manifest inspected: correct package/version, API 24 minimum/API 36 target, landscape, launcher alias, Compatibility rendering, no requested Internet permission. Archive contains ARM64 libraries and excludes project tests/docs.
- Inspection reports an unused themed-icon resource warning; standard launcher icon is present. Normal startup still reports the environment certificate-store warning; export/signing completes.
- `adb devices -l`: no device connected. This verifies packaging, not Android runtime or physical touch acceptance. The prior failed-export record below is historical and is now resolved.

## Combat stats and Android preparation

- Foundation, economy, combat-feel, enemy-behavior and stats/mobile integration suites passed in Godot 4.7.2. New coverage checks armor/dodge caps, typed damage and crit order, actual weapon critical damage, cooldown scaling, vitality, regeneration, death gating and increased pickup radius.
- Injected touch events check movement, independent second-finger dash, one-shot dash commands, drag normalization, cancellation and focus-loss cleanup. Mobile creates one local player. Opening/closing the solo character sheet pauses/resumes combat and disables/restores touch controls. These are engine tests, not physical touchscreen acceptance.
- OpenGL mobile layouts rendered at 1280x720 and 1600x720, with controls and scrollable character sheets visually inspected. Four-player desktop HUD was also rendered and inspected after the expanded catalog.
- Android debug export was attempted and failed: Java/Android SDK are not configured. Templates exist in the normal user installation; the redirected test APPDATA also prevents the export attempt from locating those templates. No APK was produced. Android installation, physical input, cutouts, suspend/resume and sustained performance remain unverified.
- The checked-in Android preset is preparation only. Online co-op, skill abilities and randomized shop stock remain future work. See `mobile-and-stats.md` for formulas, setup and extension points.

Verified September 21, 2026 using Godot **4.7.2 stable**, Windows, compatibility rendering.

- Editor import completed with all scripts registered and no script parse errors.
- `foundation_test.gd`: **PASS, 0 failures**. Exercises actual scene components, movement simulation, duplicate identity rejection, two/four player setup, death and retargeting, XP overflow, personal upgrades, immutable weapon definitions, weapon kills/rewards, all three encounter waves, party wipe and cleanup.
- `render_smoke.gd`: **PASS** on OpenGL 3.3, NVIDIA RTX 2000 Ada Generation Laptop GPU. The game ran for 180 rendered frames and saved `arena-preview.png`. The image was visually inspected: two distinct penguins, spawned enemies, arena, health bars and readable player HUD are visible.
- The main scene was also launched directly for a bounded runtime smoke check.

The restricted environment reports `Failed to read the root certificate store` at Godot startup. No network feature is used by this project. The first editor import also could not write the normal Godot user/editor directory; subsequent runs redirected `APPDATA` to workspace-local `.runtime` storage. These environment messages are separate from the passing game tests.

Limitations: movement was tested through an injected input adapter, not a human-operated keyboard/controller. No online multiplayer, physical controller acceptance, exports or long-duration performance tests were performed. Encounter completion tests accelerate spawn time and kill enemies programmatically; this proves lifecycle wiring, not combat balance. Programmer art is a foundation placeholder.

## Combat-feel update

- Foundation regression suite: **PASS, 0 failures** after the new loadouts.
- Combat-feel integration suite: **PASS, 0 failures**. Covers dash speed, active immunity and expiry, cooldown, per-player isolation, dead-player rejection, cleaver multi-target arc and range exclusions, knockback, attack cooldown, and lance single-target reach.
- OpenGL render smoke: **PASS**. Visually inspected the updated HUD, dash trail/ring, cleaver arc, enemy flashes and damage numbers in `arena-preview.png`. This is a controlled combat pose after 180 live frames, not a human playthrough. `combat-live.png` captures the unmodified live run immediately before that pose.
- Main scene ran directly for 900 frames with no gameplay script errors. The same environment certificate-store message remains.
- User-requested reset restored the original arena scene and project settings, including actor visibility. Combat changes were retained.

Physical dash buttons and gamepad mappings still require hands-on acceptance. No audio, hit-stop or screen shake was added; feedback remains local and visual so it does not interrupt co-op partners.

## Visible weapons and visual pass

- Godot imported all five original SVG assets successfully.
- Both integration suites: **PASS, 0 failures**. Added a regression check that the lance tracer does not follow a different target during cooldown.
- Live OpenGL render: **PASS**. Inspected idle and controlled-attack screenshots with visible held weapons, illustrated penguins/seal raiders, the ice-island backdrop, team cards and HUD-safe camera framing.
- Dash timings, immunity, knockback strengths, weapon damage/ranges/cooldowns and collision shapes were preserved. Visual aim updates between attacks; weapon sprites do not determine hits.
- This is an initial illustrated art pass, not final animation or art approval. Physical controller and human co-op acceptance remain separate from automated checks.

## Charging seals and snowball throwers

- All three engine integration suites passed: foundation, combat feel and enemy behavior.
- Enemy tests cover locked charge direction, recovery contact gating, light/heavy knockback interactions, ranged spacing and warnings, non-homing shots, swept nearest-player damage, single-hit consumption, dash immunity, projectile expiry, mixed wave composition, party-wipe cleanup and restart cleanup.
- `enemy_render_smoke.gd` ran through OpenGL. `enemy-warnings.png` and `enemy-attacks.png` were visually inspected for the charger lane, dotted ranged aim, distinct headgear and moving snowball. These screenshots are controlled two-enemy fixtures, not balance proof.
- The main scene ran for 900 frames without gameplay script errors. The existing environment certificate-store message remains.
- Human co-op balance and gamepad acceptance remain outstanding; the player-approved dash and weapon damage/cooldown/knockback values were preserved.

## Snowmen, material economy, harvesting and player castles

- Existing foundation, combat-feel and enemy-behavior tests passed after integration. Foundation coverage now enters the shop before selecting upgrades and explicitly enables automatic wave advance for its accelerated lifecycle test.
- Economy integration test passed: snowman destruction/drops, full-health preservation, healing caps, duplicate pickup prevention, personal currency/XP allocation, fractional Harvest yield, combat shopping lock, insufficient funds, paid/free upgrades, personal price scaling, reserve carryover, once-per-wave income, co-op readiness, castle cost/cap/placement rejection, negative-spend rejection, friendly fire exclusion, owner damage credit and restart reset.
- The OpenGL economy fixture was rendered and inspected for snowmen, snowflake/health pickups, the built castle, personal wallets, Harvest and shop/ready controls. The fixture grants test currency; live runs start at zero.
- Both two- and four-player economy layouts were visually checked. The main scene also ran for 900 frames without gameplay script errors; the known environment certificate-store message remains.
- The nurse, blacksmith, town hall, branching dungeons and full skill system are design direction only. Current limitations include fixed shop stock, one indestructible castle per player and arena-specific build bounds. Human balance and physical input acceptance remain separate.
