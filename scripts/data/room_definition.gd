class_name RoomDefinition
extends Resource
## A room owns its own space: bounds, spawn ring, prop placement and exits.
## Actors read these values instead of assuming the original centered arena.

enum Kind { COMBAT, SUPPLY, REWARD, TOWN }
enum Palette { ICE, CAVE, DEEP }

@export var id: StringName = &"room"
@export var display_name: String = "Room"
@export var kind: Kind = Kind.COMBAT
@export var palette: Palette = Palette.ICE
## Movement bounds for players and enemies, in room-local coordinates.
@export var bounds := Rect2(-540, -260, 1080, 520)
## Half-extents of the perimeter ellipse the director spawns enemies on.
@export var spawn_ring := Vector2(515, 235)
@export var supply_points: Array[Vector2] = [Vector2(-330, 110), Vector2(330, 110)]
@export var entry_point := Vector2(0, 40)
@export var encounter: EncounterDefinition
@export var exits: Array[RoomExit] = []
## Flavour line shown when the party arrives.
@export var arrival_line: String = ""

## Structures may not be placed hard against the wall.
func build_bounds() -> Rect2:
	return bounds.grow(-40.0)

func has_encounter() -> bool:
	return encounter != null
