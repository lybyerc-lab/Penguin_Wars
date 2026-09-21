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
