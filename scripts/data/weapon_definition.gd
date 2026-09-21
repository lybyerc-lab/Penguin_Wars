class_name WeaponDefinition
extends Resource
## Shared immutable definition. Cooldowns and modifiers live on WeaponController.
@export var id: StringName
@export var display_name: String
@export_range(0.1, 1000.0) var damage: float = 14.0
@export_range(0.05, 10.0) var cooldown: float = 0.65
@export_range(10.0, 1000.0) var reach: float = 190.0
