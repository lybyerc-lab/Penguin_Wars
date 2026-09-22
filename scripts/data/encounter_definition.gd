class_name EncounterDefinition
extends Resource

enum PacingMode { CLEAR_ALL, TIMED }

@export var enemy_scene: PackedScene
@export var charger_scene: PackedScene
@export var ranged_scene: PackedScene
@export_range(1, 100) var base_count: int = 6
@export_range(0.1, 10.0) var spawn_interval: float = 0.8
@export_range(1, 20) var wave_count: int = 3
@export var run_seed: int = 1729
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
