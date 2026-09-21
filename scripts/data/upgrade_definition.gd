class_name UpgradeDefinition
extends Resource

enum Stat { DAMAGE, SPEED, MAX_HEALTH, HARVEST }
@export var id: StringName
@export var display_name: String
@export var stat: Stat = Stat.DAMAGE
@export var amount: float = 3.0
@export_range(1, 1000) var snowflake_cost: int = 6
