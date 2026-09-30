class_name EncounterDefinition
extends Resource

enum PacingMode { CLEAR_ALL, TIMED }
enum SpawnMode { RING, PARTY_OFFSCREEN }
enum SectorMode { RANDOM_PAIR, HEADING }

@export var enemy_scene: PackedScene
@export var charger_scene: PackedScene
@export var ranged_scene: PackedScene
@export_range(1, 100) var base_count: int = 6
## Optional authored solo population for each wave. An empty array preserves
## the original base_count + 2 per wave progression used by existing rooms.
@export var solo_wave_populations: PackedInt32Array = PackedInt32Array()
## Additive pressure for each participating player beyond the first. Keeping this
## separate from solo population prevents co-op from multiplying role counts.
@export_range(0, 20) var additional_enemies_per_player: int = 2
@export_range(0.1, 10.0) var spawn_interval: float = 0.8
@export_range(1, 20) var wave_count: int = 3
@export var run_seed: int = 1729
## Role introductions/caps let a room teach one enemy problem at a time without
## creating a second encounter director. Existing encounters keep their old
## cadence with these defaults.
@export_range(1, 20) var charger_intro_wave: int = 1
@export_range(1, 20) var ranged_intro_wave: int = 2
@export_range(0, 40) var charger_cap: int = 40
@export_range(0, 40) var ranged_cap: int = 40
## Opt-in perimeter pressure: two separated deterministic sectors alternate
## spawn events. Other encounters retain the original global safest-point pick.
@export var split_spawn_pressure: bool = false
@export var spawn_mode: SpawnMode = SpawnMode.RING
@export var sector_mode: SectorMode = SectorMode.RANDOM_PAIR
@export var offscreen_half_extents := Vector2(880.0, 440.0)
@export var heading_min_speed: float = 40.0
@export_range(0.0, 1.0) var heading_smoothing: float = 0.6
@export var charger_caps_by_wave: PackedInt32Array = PackedInt32Array()
@export var ranged_caps_by_wave: PackedInt32Array = PackedInt32Array()
## Legacy encounters wait for every enemy. Timed encounters survive until the
## per-wave duration expires and are enabled only by explicit encounter data.
@export var pacing_mode: PacingMode = PacingMode.CLEAR_ALL
@export var timed_wave_durations: PackedFloat32Array = PackedFloat32Array()
@export_range(0.5, 10.0) var intermission_duration: float = 3.0
@export_range(1, 40) var timed_max_alive: int = 8
## Fought after the last wave. Null means the room ends when the waves do.
@export var boss: BossDefinition
## Scales spawned enemy health and damage, so one room can be harder than
## another without a second set of enemy scenes.
@export_range(0.1, 10.0) var difficulty_multiplier: float = 1.0

func uses_timed_waves() -> bool:
	return pacing_mode == PacingMode.TIMED and not timed_wave_durations.is_empty()

func duration_for_wave(wave_number: int) -> float:
	if not uses_timed_waves():
		return 0.0
	var index: int = clampi(wave_number - 1, 0, timed_wave_durations.size() - 1)
	return timed_wave_durations[index]

func population_for_wave(wave_number: int, active_player_count: int) -> int:
	var solo: int = base_count + maxi(0, wave_number - 1) * 2
	var index: int = wave_number - 1
	if index >= 0 and index < solo_wave_populations.size():
		solo = solo_wave_populations[index]
	return solo + maxi(0, active_player_count - 1) * additional_enemies_per_player

func charger_cap_for_wave(wave_number: int) -> int:
	return _wave_cap(charger_caps_by_wave, wave_number, charger_cap)

func ranged_cap_for_wave(wave_number: int) -> int:
	return _wave_cap(ranged_caps_by_wave, wave_number, ranged_cap)

func _wave_cap(values: PackedInt32Array, wave_number: int, fallback: int) -> int:
	if values.is_empty(): return fallback
	return values[clampi(wave_number - 1, 0, values.size() - 1)]
