class_name EncounterDefinition
extends Resource

@export var enemy_scene: PackedScene
@export var charger_scene: PackedScene
@export var ranged_scene: PackedScene
@export_range(1, 100) var base_count: int = 6
@export_range(0.1, 10.0) var spawn_interval: float = 0.8
@export_range(1, 20) var wave_count: int = 3
@export var run_seed: int = 1729
## Fought after the last wave. Null means the room ends when the waves do.
@export var boss: BossDefinition
## Scales spawned enemy health and damage, so one room can be harder than
## another without a second set of enemy scenes.
@export_range(0.1, 10.0) var difficulty_multiplier: float = 1.0
