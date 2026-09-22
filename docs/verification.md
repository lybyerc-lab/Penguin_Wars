# Verification record

## Boss milestones and war ending

- Boss/campaign integration passes: milestone precedence through cave 60, boss health scaling for co-op, locked harmless windups, charge/recovery contact gating, resistance to stun-lock, Warden volleys, Mondo enrage/slam/dash immunity, boss rewards paid once, projectile cleanup, blocked premature exits, mobile campaign-choice controls, preserved endless state, peaceful ending and party-wipe rejection.
- Foundation, cave-journey, combat-feel, enemy-behavior and economy regressions passed. Controlled OpenGL fixtures for all three boss tiers, the mobile cave-20 choice and the town ending were visually inspected.
- Tests accelerate waves and deal scripted lethal damage. They verify lifecycle and combat rules, not 20 caves of human balance or Android performance. Boss appearances are initial crown/seal art. Physical phone testing, saves and online authority remain outstanding.

## Cave completion, exits and town staging

- Cave journey integration passed: exits locked during combat; actual multi-wave completion shows the banner; town retains build/HP/XP/level/wallet/free choices/reserve; town stops combat and rejects building; subsequent caves reset supplies and pay wave-one income exactly once; duplicate travel is rejected; direct next-cave travel and mobile button paths work.
- Foundation, economy, stats/mobile and full-screen HUD regression suites passed after integration. Desktop and mobile completion/town screenshots were rendered and visually inspected.
- Town is a minimal staging area. Named building services, revival, persistent saves, distinct cave geometry and online travel consensus are not implemented. No phone was connected for physical device acceptance.

## Full-screen arena and corner HUD

- Replaced the inset island and reserved HUD strips with a viewport-filling floor, fixed camera and shared resizable room bounds. Castle placement and enemy shots follow the expanded room.
- Active players receive corner portraits with matching scarves, health bars, levels and personal flakes. Selecting a card opens that player's character sheet. The location appears at screen center and fades away after arrival; it does not capture input.
- All six integration suites pass, including new corner assignment, live health/wallet readouts, correct-player sheet selection, full-room coverage, enemy bounds and banner removal checks. The prior foundation test's fixed old arena limit was updated to assert the current bounds.
- Two/four-player desktop and standard/wide mobile layouts rendered for inspection. Android debug APK rebuilt with this layout; physical device acceptance remains pending.

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
