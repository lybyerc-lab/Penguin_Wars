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
## TownshipVisualV1 owns the physical building art. Existing service behavior
## remains visible as a small ground marker at the matching doorway.
var structure_visible: bool = true

func _ready() -> void:
	z_index = -1
	queue_redraw()

func _process(_delta: float) -> void:
	# Four tiny service pads are cheap to redraw and this keeps their occupied
	# highlight honest without adding another signal/state system.
	queue_redraw()

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
	if party == null:
		return false
	var activators: Array[PenguinPlayer] = occupants()
	if activators.is_empty():
		return false
	for player: PenguinPlayer in party.members(true):
		var close_to_activator: bool = activators.any(func(activator: PenguinPlayer) -> bool:
			return player.global_position.distance_to(activator.global_position) <= CAMERA_GROUP_RADIUS
		)
		if not close_to_activator:
			return false
	return true

func _draw() -> void:
	var active: bool = not occupants().is_empty()
	var visual_radius: float = 66.0
	var outer: Color = Color(tint, 0.72 if active else 0.34)
	var inner: Color = Color(tint, 0.18 if active else 0.08)

	# Packed-snow / stone threshold medallion. The interaction radius remains
	# larger than the art so players do not need pixel-perfect positioning.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, visual_radius + 9.0, Color(0.94, 0.98, 1.0, 0.30 if active else 0.16))
	draw_circle(Vector2.ZERO, visual_radius, inner)
	draw_arc(Vector2.ZERO, visual_radius, 0.0, TAU, 48, outer, 3.0 if active else 2.0)
	if active:
		draw_arc(Vector2.ZERO, visual_radius - 8.0, 0.0, TAU, 48, Color(tint, 0.42), 2.0)
	draw_set_transform(Vector2.ZERO)

	_draw_service_mark(active)

	if not structure_visible:
		if active:
			draw_string(
				ThemeDB.fallback_font,
				Vector2(-120, -88),
				title,
				HORIZONTAL_ALIGNMENT_CENTER,
				240,
				17,
				Color(tint.lightened(0.30))
			)
		return

	# Fallback structure art used only when TownshipVisualV1 is unavailable.
	draw_colored_polygon(PackedVector2Array([Vector2(-58, -20), Vector2(58, -20), Vector2(58, -78), Vector2(-58, -78)]), Color("dfeef4"))
	for row: int in range(3):
		draw_line(Vector2(-58, -32.0 - row * 15.0), Vector2(58, -32.0 - row * 15.0), Color("b6cdd8"), 2)
	draw_colored_polygon(PackedVector2Array([Vector2(-70, -78), Vector2(70, -78), Vector2(0, -126)]), tint)
	draw_colored_polygon(PackedVector2Array([Vector2(-70, -78), Vector2(0, -126), Vector2(0, -112), Vector2(-52, -78)]), Color(tint.lightened(0.22)))
	draw_colored_polygon(PackedVector2Array([Vector2(-17, -20), Vector2(17, -20), Vector2(17, -58), Vector2(-17, -58)]), Color("2f4a5c"))
	draw_circle(Vector2(10, -38), 3, Color("ffe6a8"))
	draw_line(Vector2(58, -70), Vector2(84, -70), Color("8a6a4a"), 3)
	draw_colored_polygon(PackedVector2Array([Vector2(68, -68), Vector2(100, -68), Vector2(100, -44), Vector2(68, -44)]), Color("3a2e26"))
	draw_rect(Rect2(70, -66, 28, 20), tint, false, 2)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(-120, -150), title, HORIZONTAL_ALIGNMENT_CENTER, 240, 16, Color("f2fbff"))
	if not keeper.is_empty():
		draw_string(font, Vector2(-120, -134), keeper, HORIZONTAL_ALIGNMENT_CENTER, 240, 12, Color(tint, 0.9))

func _draw_service_mark(active: bool) -> void:
	var ink := Color(tint.lightened(0.42), 0.95 if active else 0.65)
	match kind:
		Kind.SHOP:
			# Fish: body + tail + eye.
			draw_colored_polygon(PackedVector2Array([
				Vector2(-25, 0), Vector2(-8, -11), Vector2(16, -8),
				Vector2(27, 0), Vector2(16, 8), Vector2(-8, 11),
			]), ink)
			draw_colored_polygon(PackedVector2Array([Vector2(-24, 0), Vector2(-39, -13), Vector2(-39, 13)]), ink)
			draw_circle(Vector2(15, -2), 2.5, Color("173244"))
		Kind.NURSE:
			draw_rect(Rect2(-8, -28, 16, 56), ink)
			draw_rect(Rect2(-28, -8, 56, 16), ink)
		Kind.BLACKSMITH:
			# Small hammer silhouette.
			draw_rect(Rect2(-25, -20, 36, 15), ink)
			draw_rect(Rect2(2, -10, 10, 39), ink)
		Kind.TOWN_HALL:
			# Simple civic diamond/crest, distinct from combat telegraphs.
			var crest := PackedVector2Array([
				Vector2(0, -27), Vector2(23, 0), Vector2(0, 27), Vector2(-23, 0)
			])
			draw_colored_polygon(crest, ink)
			draw_circle(Vector2.ZERO, 7, Color("173244", 0.65))
