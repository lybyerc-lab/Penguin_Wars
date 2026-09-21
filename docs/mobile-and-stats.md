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

The Android preset targets ARM64 APKs and excludes tests/docs. It contains no signing secrets or machine-specific SDK paths. Builds go into ignored `builds/`. It is an export starting point, not a validated mobile release.

Godot 4.7.2 Android templates are installed on this PC. Java and Android SDK paths are not configured; the attempted debug export failed and no APK was produced. Follow the [official Godot Android export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) to install OpenJDK 17 and the required SDK packages, then set Java SDK Path and Android SDK Path in Godot's Editor Settings. With templates and debug signing configured, create `builds/` and run `godot --headless --path . --export-debug Android`.

Desktop rendering and injected touch tests are verified; installation, real multitouch, cutouts, Android suspend/resume, thermal behavior and sustained frame rate require an actual device. No online connection or Internet permission is enabled. A future network session must replace the solo-only pause policy and map one local input adapter to each remote player identity.
