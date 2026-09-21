class_name RoomExit
extends Resource
## One way out of a room. Targets are named, not referenced, so room
## resources never form a cycle and a cave owns its own route graph.

## Empty target means "leave the cave and return to town".
@export var target_id: StringName = &""
@export var label: String = "Onward"
## Short risk/reward line shown on the gate so a branch can be read before it is taken.
@export var hint: String = ""
@export var position := Vector2(500, 0)

func leads_outside() -> bool:
	return target_id == &""
