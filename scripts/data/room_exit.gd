class_name RoomExit
extends Resource
## One way out of a room. Targets are named, not referenced, so room
## resources never form a cycle and a cave owns its own route graph.

## Which wall the doorway sits on.
enum Side { LEFT, RIGHT, TOP, BOTTOM }

## Empty target means "leave the cave and return to town".
@export var target_id: StringName = &""
@export var label: String = "Onward"
@export var hint: String = ""
@export var side := Side.BOTTOM
## Legacy / override position. When side is set, place_at_wall() computes the
## real position from the room bounds; this field is only a fallback.
@export var position := Vector2(500, 0)

func leads_outside() -> bool:
	return target_id == &""

## Compute a doorway position flush against the given wall of the room.
## offset_along is 0.0 for centered, negative for left/up, positive for right/down.
static func wall_position(bounds: Rect2, wall: int, offset_along: float = 0.0) -> Vector2:
	var center: Vector2 = bounds.get_center()
	var half: Vector2 = bounds.size * 0.5
	match wall:
		Side.LEFT:
			return Vector2(bounds.position.x, center.y + offset_along)
		Side.RIGHT:
			return Vector2(bounds.end.x, center.y + offset_along)
		Side.TOP:
			return Vector2(center.x + offset_along, bounds.position.y)
		Side.BOTTOM:
			return Vector2(center.x + offset_along, bounds.end.y)
	return center
