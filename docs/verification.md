# Verification record

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
