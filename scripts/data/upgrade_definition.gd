class_name UpgradeDefinition
extends Resource

enum Stat { DAMAGE, SPEED, MAX_HEALTH, HARVEST, ARMOR, REGENERATION, DAMAGE_PERCENT, MELEE_DAMAGE, RANGED_DAMAGE, ATTACK_SPEED, CRITICAL_CHANCE, DODGE, PICKUP_RANGE, ENGINEERING, RANGE }
@export var id: StringName
@export var display_name: String
@export var stat: Stat = Stat.DAMAGE
@export var amount: float = 3.0
@export_range(1, 1000) var snowflake_cost: int = 6
