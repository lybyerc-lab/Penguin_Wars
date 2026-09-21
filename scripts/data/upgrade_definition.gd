class_name UpgradeDefinition
extends Resource

enum Stat { DAMAGE, SPEED, MAX_HEALTH }
@export var id: StringName
@export var display_name: String
@export var stat: Stat = Stat.DAMAGE
@export var amount: float = 3.0
