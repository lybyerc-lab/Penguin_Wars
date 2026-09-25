class_name TownService
extends Node2D
## A building the party can stand in front of. Occupancy is positional, so the
## town adds no input bindings: the same keys that pick wave-shop upgrades pick
## service options while a penguin is inside the zone.

enum Kind { SHOP, NURSE, BLACKSMITH, TOWN_HALL }
const RADIUS: float = 96.0
const CAMERA_GROUP_RADIUS: float = 420.0

var kind: Kind = Kind.SHOP
var title: String = "Stall"
var keeper: String = ""
var tint: Color = Color("f0c987")
var party: PartyRoster
var camera_focus_point := Vector2.ZERO
## The Township V0.1 scene owns the physical building art. Existing service
## behavior remains visible as a small ground marker at the matching doorway.
var structure_visible: bool = true

func _ready() -> void:
	z_index = -1

func occupants() -> Array[PenguinPlayer]:
	var result: Array[PenguinPlayer] = []
	if party == null:
		return result
	for player: PenguinPlayer in party.members(true):
		if player.global_position.distance_to(global_position) <= RADIUS:
			result.append(player)
	return result

## Camera focus is allowed when at least one player uses the pad and every
## living party member remains close enough to share the same local moment.
func allows_camera_focus() -> bool:
	if party == null or occupants().is_empty():
		return false
	for player: PenguinPlayer in party.members(true):
		if player.global_position.distance_to(global_position) > CAMERA_GROUP_RADIUS:
			return false
	return true

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, RADIUS, Color(tint, 0.10))
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 48, Color(tint, 0.45), 2)
	draw_set_transform(Vector2.ZERO)
	if not structure_visible:
		draw_string(ThemeDB.fallback_font, Vector2(-100, -10), title, HORIZONTAL_ALIGNMENT_CENTER, 200, 14, Color(tint.lightened(0.25)))
		return
	# Snow-block hut with a coloured roof so services read apart at a glance.
	draw_colored_polygon(PackedVector2Array([Vector2(-58, -20), Vector2(58, -20), Vector2(58, -78), Vector2(-58, -78)]), Color("dfeef4"))
	for row: int in range(3):
		draw_line(Vector2(-58, -32.0 - row * 15.0), Vector2(58, -32.0 - row * 15.0), Color("b6cdd8"), 2)
	draw_colored_polygon(PackedVector2Array([Vector2(-70, -78), Vector2(70, -78), Vector2(0, -126)]), tint)
	draw_colored_polygon(PackedVector2Array([Vector2(-70, -78), Vector2(0, -126), Vector2(0, -112), Vector2(-52, -78)]), Color(tint.lightened(0.22)))
	draw_colored_polygon(PackedVector2Array([Vector2(-17, -20), Vector2(17, -20), Vector2(17, -58), Vector2(-17, -58)]), Color("2f4a5c"))
	draw_circle(Vector2(10, -38), 3, Color("ffe6a8"))
	# Hanging sign.
	draw_line(Vector2(58, -70), Vector2(84, -70), Color("8a6a4a"), 3)
	draw_colored_polygon(PackedVector2Array([Vector2(68, -68), Vector2(100, -68), Vector2(100, -44), Vector2(68, -44)]), Color("3a2e26"))
	draw_rect(Rect2(70, -66, 28, 20), tint, false, 2)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(-120, -150), title, HORIZONTAL_ALIGNMENT_CENTER, 240, 16, Color("f2fbff"))
	if not keeper.is_empty():
		draw_string(font, Vector2(-120, -134), keeper, HORIZONTAL_ALIGNMENT_CENTER, 240, 12, Color(tint, 0.9))
