class_name CaveDefinition
extends Resource
## A cave is a named set of rooms plus the entrance. Rooms reference each
## other by id, so this resource is the only place the route graph lives.

@export var id: StringName = &"cave"
@export var display_name: String = "Cave"
## Line the town shows on the entrance signpost.
@export var signpost: String = ""
@export var rooms: Array[RoomDefinition] = []

func entrance() -> RoomDefinition:
	return rooms[0] if not rooms.is_empty() else null

func room(id_to_find: StringName) -> RoomDefinition:
	for candidate: RoomDefinition in rooms:
		if candidate != null and candidate.id == id_to_find:
			return candidate
	return null

## Every exit must resolve, or the cave is unplayable. Used by tests.
func unresolved_exits() -> PackedStringArray:
	var missing := PackedStringArray()
	for candidate: RoomDefinition in rooms:
		if candidate == null:
			continue
		for exit: RoomExit in candidate.exits:
			if not exit.leads_outside() and room(exit.target_id) == null:
				missing.append("%s -> %s" % [candidate.id, exit.target_id])
	return missing
