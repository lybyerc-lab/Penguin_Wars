class_name RoomExit
extends Resource
## One way out of a room. Targets are named, not referenced, so room
## resources never form a cycle and a cave owns its own route graph.

## Which wall the doorway sits on.
enum Side { LEFT, RIGHT, TOP, BOTTOM }

## How a doorway is dressed. Presentation only: it never affects travel,
## targeting, geometry or which room lies beyond. Art picks its look from this
## rather than from the name of the room on the other side.
enum Presentation { STANDARD, EXPEDITION_MOUTH, CRYSTAL, FRACTURED }

## Empty target means "leave the cave and return to town".
@export var target_id: StringName = &""
@export var label: String = "Onward"
@export var hint: String = ""
@export var side := Side.BOTTOM
## How far along its wall the doorway sits, in room pixels, measured from the
## middle of that wall. Negative is left or up, positive is right or down, and
## 0.0 centres it. This is what lets one wall carry more than one doorway.
@export var offset_along: float = 0.0
@export var presentation := Presentation.STANDARD
## Legacy / override position. When side is set, place_on() computes the real
## position from the room bounds; this field is only a fallback.
@export var position := Vector2(500, 0)

func leads_outside() -> bool:
	return target_id == &""

## Where this doorway sits on the wall of the room that owns it. The single
## call site for doorway placement: gates and wall art both use it, so they
## cannot disagree.
func place_on(bounds: Rect2) -> Vector2:
	return wall_position(bounds, side, offset_along)

## Compute a doorway position flush against the given wall of the room.
## offset_along is 0.0 for centered, negative for left/up, positive for right/down.
static func wall_position(bounds: Rect2, wall: int, offset_along: float = 0.0) -> Vector2:
	var center: Vector2 = bounds.get_center()
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
