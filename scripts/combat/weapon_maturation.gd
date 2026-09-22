class_name WeaponMaturation
extends RefCounted
## Immutable report of one rack pair resolved during a maturation event.

var family_id: StringName
var keep_slot: int
var consumed_slot: int
var previous_definition: WeaponDefinition
var resulting_definition: WeaponDefinition

func _init(before: WeaponDefinition, after: WeaponDefinition, kept: int, consumed: int) -> void:
	family_id = before.family_id
	previous_definition = before
	resulting_definition = after
	keep_slot = kept
	consumed_slot = consumed
