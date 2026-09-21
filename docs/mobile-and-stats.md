# Combat stats and Android foundation

The direction is Brotato-style combat stats with RPG flavor, Android first, one local player per phone. Desktop keeps 1–4 local players. Online co-op is not implemented.

## Try it on PC

Run `godot --path . -- --mobile`, or enable `TestArena.mobile_preview` in the inspector. Drag the left joystick with the mouse, use the right Dash button, and use the top buttons for castle placement, shopping, readying and restarting. Attacks remain automatic. A physical touchscreen supports movement and dash on separate fingers. Desktop keyboard controls remain available in preview.

On Android the mobile layout and one-player party are selected automatically. The landscape layout expands to wider screens, uses safe-area insets for the HUD and touch controls, and keeps Compatibility rendering. Character / Shop opens the scrollable catalog and pauses solo mobile combat until closed. Desktop character sheets do not pause shared co-op combat. Opening a sheet or losing application focus clears touch movement so it cannot stick.

## Stats and tuning

Each penguin has a fresh `PlayerStats` Resource; upgrades do not mutate shared definitions. There are 15 catalog entries, with the original three retained as desktop shortcuts. Purchases still use personal snowflakes or pending free level-up choices between waves.

| Stat | Current effect |
| --- | --- |
| Vitality | +20 maximum HP and heals that amount |
| Sharp Ice | +3 flat weapon damage |
| Swift Flippers | +15 movement speed |
| Harvest | +0.25 income multiplier, retaining fractional earnings |
| Armor | +2; incoming damage multiplied by `100 / (100 + armor * 5)`; negative armor treated as zero |
| Regeneration | +1 HP per second while alive |
| Might | +10 percentage points of weapon damage |
| Melee / Ranged | +3 / +2 flat damage for matching weapon type |
| Haste | +10 percentage points of attack speed |
| Precision | +5 percentage points of critical chance, capped at 100%; crits deal 1.5x |
| Evasion | +5 percentage points of dodge, capped at 60% |
| Gathering | +20 pixels of pickup radius |
| Engineering | +2 damage for that player's castle shots |
| Reach | +15 pixels of weapon reach |

Weapon damage applies base + Sharp Ice + type bonus, then percentage damage, then critical multiplier. Cooldown is base cooldown divided by `1 + attack_speed / 100`, with a 0.08-second minimum. Percentage damage and attack-speed factors have positive floors. These are our initial balance formulas, not a claim to reproduce Brotato's exact rules. The Ice Lance is classified as ranged and Fish Cleaver as melee. Castle damage currently scales only with Engineering.

`PlayerStats` owns formulas, `Health.defenses` applies dodge/armor, `WeaponController` applies weapon stats, and `RunPickup` and `SnowCastle` consume their relevant bonuses. `UpgradeDefinition.Stat` and `.tres` Resources define catalog changes. Existing enum values are preserved. Extend with a modifier aggregator before adding timed buffs, equipment removal or complex stacking. Future network authority must own random rolls, damage, purchases and rewards.

## Android build status

The Android preset targets ARM64 APKs and excludes tests/docs. It contains no signing secrets or machine-specific SDK paths. Builds go into ignored `builds/`. Debug export now succeeds and APK v2/v3 signatures and 16 KB page alignment pass validation. This is a development build, not a validated mobile release.

This PC now has portable Temurin Java 17.0.20.1 and Android command-line tools under the workspace's `.android-tools/` directory, outside the Git repository. Installed SDK packages include platform-tools 37.0.1, Build Tools 36.0.0 and Platform 36, matching the installed Godot 4.7.2 template's target SDK. The initial Platform/Build Tools 35 packages are also installed. NDK/CMake and Android Studio are not needed for this successful prebuilt-template APK path; native/Gradle extensions may need additional tooling.

Both normal Godot editor settings and workspace `.runtime/Godot` settings point to those tools and the development signing key. Previous normal editor settings were backed up under `.android-tools/editor_settings-before-android.tres`. If an already-running editor shows stale paths, restart it and verify Java SDK Path and Android SDK Path. The project explicitly sets the mobile renderer to Compatibility and enables Android texture imports.

From the repository, run `./tools/build-android.ps1 -WorkspaceToolchain`. It imports assets, exports the Android preset, and fails on a nonzero Godot exit. On another PC, follow the [official Godot Android export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html), configure local editor paths/templates/signing, and run `./tools/build-android.ps1` without the workspace flag. Java/SDK installations and development keys are deliberately not committed.

The APK is `builds/penguin-wars-debug.apk`, package `org.lybyerlab.penguinwars`, version 0.1.0, minimum API 24, target API 36, ARM64 and landscape. Transfer it to a compatible Android phone and open it to install; Android may ask to allow installation from the chosen file app. For USB testing, enable developer options/USB debugging, authorize the PC, then use the workspace SDK's `platform-tools/adb.exe install -r builds/penguin-wars-debug.apk`. No device was connected during build verification. Do not use this public development-key setup for a store release.

Desktop rendering and injected touch tests are verified; installation, real multitouch, cutouts, Android suspend/resume, thermal behavior and sustained frame rate require an actual device. No online connection or Internet permission is enabled. A future network session must replace the solo-only pause policy and map one local input adapter to each remote player identity. The APK inspection tool reports an unused themed-icon resource warning from the template; standard launcher icon resources and launcher activity alias are present. Check themed icons during device acceptance.
