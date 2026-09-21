class_name RoomVisual
extends Node2D
## Seeded decorative art only. Does not define collisions or spawn positions.
## Every shape is derived from the room bounds, so one script dresses the
## original ice arena and any later cave room at its own size.
## Doorway openings are cleanly cut into the wall boundary with environmental
## framing, wall thickness, and floor grounding.

## Palettes are indexed by RoomDefinition.Palette.
const PALETTES: Array[Dictionary] = [
	{
		# 0: ICE (Town, Frostfall Arena)
		"backdrop": Color("102d44"), "streak": Color("1e4058"), "rim": Color("214559"),
		"shelf": Color("80bac9"), "floor": Color("397487"), "border": Color("c0e4e2"),
		"speck": Color(0.7, 0.94, 0.96, 0.10), "crack": Color("2d6177"),
		"crack_light": Color(0.6, 0.88, 0.95, 0.22), "ring": Color(0.7, 0.95, 1.0, 1.0),
		"crystal_dark": Color("183e58"), "crystal_mid": Color("7bc9d8"),
		"crystal_light": Color("b4e9e9"), "crystal_edge": Color("f1ffff"),
		"drift_dark": Color("a2ced7"), "drift_light": Color("e1f0e9"),
		"passage": Color("0a1824"),
		"tunnel_mouth": Color("142e3d"), "tunnel_mid": Color("0c1c26"), "tunnel_deep": Color("050e14"),
	},
	{
		# 1: CAVE (The Hollow Shelf, Cracked Gallery)
		"backdrop": Color("161127"), "streak": Color("241d3d"), "rim": Color("2a2140"),
		"shelf": Color("6b5a86"), "floor": Color("3c3357"), "border": Color("9d8bc0"),
		"speck": Color(0.85, 0.78, 1.0, 0.10), "crack": Color("4b3d70"),
		"crack_light": Color(0.78, 0.68, 0.98, 0.22), "ring": Color(0.85, 0.78, 1.0, 1.0),
		"crystal_dark": Color("2a1f42"), "crystal_mid": Color("8f7bc9"),
		"crystal_light": Color("c3b0e9"), "crystal_edge": Color("f4ecff"),
		"drift_dark": Color("6d5f8c"), "drift_light": Color("cdbde8"),
		"passage": Color("0e0a1a"),
		"tunnel_mouth": Color("221834"), "tunnel_mid": Color("140c20"), "tunnel_deep": Color("07040d"),
	},
	{
		# 2: DEEP (The Glitter Seam, The Black Ledge)
		"backdrop": Color("0a1620"), "streak": Color("12303c"), "rim": Color("163445"),
		"shelf": Color("3f8f8c"), "floor": Color("1d4b52"), "border": Color("68c9b6"),
		"speck": Color(0.6, 1.0, 0.92, 0.10), "crack": Color("205f60"),
		"crack_light": Color(0.5, 0.95, 0.85, 0.22), "ring": Color(0.6, 1.0, 0.92, 1.0),
		"crystal_dark": Color("10303a"), "crystal_mid": Color("3fae9d"),
		"crystal_light": Color("8fe6cf"), "crystal_edge": Color("e8fff8"),
		"drift_dark": Color("3e7f80"), "drift_light": Color("bfe8dd"),
		"passage": Color("061218"),
		"tunnel_mouth": Color("12272e"), "tunnel_mid": Color("08171d"), "tunnel_deep": Color("030b0e"),
	},
]

## Fractions of the bounds half-extents. Values above 1.0 sit on the rim.
const CRACKS: Array[Vector2] = [Vector2(-0.8889, -0.6923), Vector2(0.5556, 0.6538), Vector2(-0.6852, 0.6538), Vector2(0.8704, -0.4231)]
const CRYSTALS: Array[Vector2] = [Vector2(-1.0426, -0.9), Vector2(-1.05, 0.8269), Vector2(1.037, -0.8115), Vector2(1.0241, 0.9462), Vector2(-0.6574, 1.0846), Vector2(0.687, -1.0962)]
const DRIFTS: Array[Vector2] = [Vector2(-0.8704, -1.0654), Vector2(0.3704, 1.0462), Vector2(0.8704, 1.0808), Vector2(-0.3148, -1.0846)]

## Width of a standard cave doorway opening in the wall.
const DOORWAY_WIDTH: float = 140.0
## Width of the grand expedition cave mouth in Kelphollow town.
const TOWN_MOUTH_WIDTH: float = 210.0

@export var bounds := Rect2(-540, -260, 1080, 520):
	set(value):
		bounds = value
		queue_redraw()
@export var palette: int = 0:
	set(value):
		palette = value
		queue_redraw()
@export var seed_value: int = 92:
	set(value):
		seed_value = value
		queue_redraw()

## Doorway data set by the room setup. Each entry is
## {side: int, position: Vector2, presentation: int}, where presentation is a
## RoomExit.Presentation value. Doorway art never reads the name of the room on
## the other side.
var doorways: Array[Dictionary] = []:
	set(value):
		doorways = value
		queue_redraw()

func _at(fraction: Vector2) -> Vector2:
	return bounds.get_center() + bounds.size * 0.5 * fraction

func _draw() -> void:
	var skin: Dictionary = PALETTES[clampi(palette, 0, PALETTES.size() - 1)]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var center: Vector2 = bounds.get_center()

	# 1. Outer deep backdrop.
	draw_rect(Rect2(center - Vector2(1500, 1000), Vector2(3000, 2000)), skin["backdrop"])
	for index: int in range(90):
		var point := center + Vector2(rng.randf_range(-900, 900), rng.randf_range(-600, 600))
		draw_line(point, point + Vector2(rng.randf_range(12, 55), 0), skin["streak"], 2)

	# 2. Layered room embankment & floor base.
	var floor_rect: Rect2 = bounds.grow_individual(35, 40, 35, 25)

	# Rim layer (outer stone/ice embankment)
	var edge := StyleBoxFlat.new()
	edge.bg_color = skin["rim"]
	edge.set_corner_radius_all(48)
	draw_style_box(edge, floor_rect.grow_individual(15, -20, 15, 35))

	# Shelf layer (middle ice ledge)
	edge.bg_color = skin["shelf"]
	draw_style_box(edge, floor_rect.grow_individual(9, -1, 9, 10))

	# Combat floor (inner walkable floor fill, without solid closed border)
	edge.bg_color = skin["floor"]
	edge.set_border_width_all(0)
	draw_style_box(edge, floor_rect)

	# 3. Punch doorway cutouts through the wall embankment and draw wall borders.
	_draw_walls_and_doorways(skin, floor_rect)

	# 4. Arena interior details.
	var speck_area: Rect2 = bounds.grow_individual(-10, -15, -10, -20)
	for index: int in range(55):
		var point := Vector2(rng.randf_range(speck_area.position.x, speck_area.end.x), rng.randf_range(speck_area.position.y, speck_area.end.y))
		draw_circle(point, rng.randf_range(2, 6), skin["speck"])

	# Sparse angular cracks keep the combat floor readable.
	for fraction: Vector2 in CRACKS:
		var origin: Vector2 = _at(fraction)
		var points := PackedVector2Array([origin, origin + Vector2(50, 15), origin + Vector2(80, -12), origin + Vector2(125, 7)])
		draw_polyline(points, skin["crack"], 3, true)
		draw_polyline(points, skin["crack_light"], 1, true)
		draw_line(origin + Vector2(50, 15), origin + Vector2(55, 48), skin["crack"], 2)

	var ring: Color = skin["ring"]
	draw_arc(center, 90, 0, TAU, 64, Color(ring, 0.12), 3)
	draw_arc(center, 100, 0, TAU, 64, Color(ring, 0.08), 1)

	for fraction: Vector2 in CRYSTALS:
		_draw_crystal(_at(fraction), skin)

	for fraction: Vector2 in DRIFTS:
		draw_set_transform(_at(fraction), 0, Vector2(1, 0.35))
		draw_circle(Vector2.ZERO, 26, skin["drift_dark"])
		draw_circle(Vector2(-3, -5), 21, skin["drift_light"])

	draw_set_transform(Vector2.ZERO)

## Draws the room wall borders with clean physical openings where doorways sit.
func _draw_walls_and_doorways(skin: Dictionary, floor_rect: Rect2) -> void:
	var border_color: Color = skin["border"]
	var border_width: float = 12.0
	var corner_rad: float = 48.0
	var offset: float = border_width * 0.5

	var tl := floor_rect.position + Vector2(offset, offset)
	var br := floor_rect.end - Vector2(offset, offset)

	# 1. First, carve the doorway cavities and floor grounding.
	for door: Dictionary in doorways:
		_carve_doorway_opening(skin, floor_rect, door)

	# 2. Draw the 4 rounded corner arcs.
	draw_arc(Vector2(tl.x + corner_rad, tl.y + corner_rad), corner_rad, PI, 1.5 * PI, 16, border_color, border_width)
	draw_arc(Vector2(br.x - corner_rad, tl.y + corner_rad), corner_rad, 1.5 * PI, TAU, 16, border_color, border_width)
	draw_arc(Vector2(br.x - corner_rad, br.y - corner_rad), corner_rad, 0.0, 0.5 * PI, 16, border_color, border_width)
	draw_arc(Vector2(tl.x + corner_rad, br.y - corner_rad), corner_rad, 0.5 * PI, PI, 16, border_color, border_width)

	# 3. Draw each straight wall segment, breaking cleanly at any doorway.
	_draw_wall_edge_with_doors(border_color, border_width,
		Vector2(tl.x + corner_rad, tl.y), Vector2(br.x - corner_rad, tl.y),
		RoomExit.Side.TOP, true)

	_draw_wall_edge_with_doors(border_color, border_width,
		Vector2(tl.x + corner_rad, br.y), Vector2(br.x - corner_rad, br.y),
		RoomExit.Side.BOTTOM, true)

	_draw_wall_edge_with_doors(border_color, border_width,
		Vector2(tl.x, tl.y + corner_rad), Vector2(tl.x, br.y - corner_rad),
		RoomExit.Side.LEFT, false)

	_draw_wall_edge_with_doors(border_color, border_width,
		Vector2(br.x, tl.y + corner_rad), Vector2(br.x, br.y - corner_rad),
		RoomExit.Side.RIGHT, false)

func _is_expedition_mouth(door: Dictionary) -> bool:
	return int(door.get("presentation", RoomExit.Presentation.STANDARD)) == RoomExit.Presentation.EXPEDITION_MOUTH

func _get_door_width(door: Dictionary) -> float:
	return TOWN_MOUTH_WIDTH if _is_expedition_mouth(door) else DOORWAY_WIDTH

func _carve_doorway_opening(skin: Dictionary, floor_rect: Rect2, door: Dictionary) -> void:
	var s: int = door.get("side", RoomExit.Side.BOTTOM)
	var pos: Vector2 = door.get("position", bounds.get_center())
	var dress: int = int(door.get("presentation", RoomExit.Presentation.STANDARD))
	var is_town_mouth: bool = dress == RoomExit.Presentation.EXPEDITION_MOUTH
	var door_w: float = _get_door_width(door)
	var half_w: float = door_w * 0.5

	var depth: float = 65.0
	var cavity_rect: Rect2
	var floor_lip_rect: Rect2

	match s:
		RoomExit.Side.LEFT:
			cavity_rect = Rect2(floor_rect.position.x - depth, pos.y - half_w, depth + 15.0, door_w)
			floor_lip_rect = Rect2(floor_rect.position.x, pos.y - half_w, 35.0, door_w)
		RoomExit.Side.RIGHT:
			cavity_rect = Rect2(floor_rect.end.x - 15.0, pos.y - half_w, depth + 15.0, door_w)
			floor_lip_rect = Rect2(floor_rect.end.x - 35.0, pos.y - half_w, 35.0, door_w)
		RoomExit.Side.TOP:
			cavity_rect = Rect2(pos.x - half_w, floor_rect.position.y - depth, door_w, depth + 15.0)
			floor_lip_rect = Rect2(pos.x - half_w, floor_rect.position.y, door_w, 35.0)
		RoomExit.Side.BOTTOM:
			cavity_rect = Rect2(pos.x - half_w, floor_rect.end.y - 15.0, door_w, depth + 15.0)
			floor_lip_rect = Rect2(pos.x - half_w, floor_rect.end.y - 35.0, door_w, 35.0)

	# 1. Cut through the wall rim with backdrop color.
	draw_rect(cavity_rect, skin["backdrop"])

	# 2. Recessed tunnel mouth with palette-aware depth tone.
	var mouth_color: Color = skin.get("tunnel_mouth", skin["passage"])
	draw_rect(cavity_rect.grow(-3), mouth_color)

	# 3. Floor grounding: subtle worn path and soft shadow in front of doorway.
	var path_color := Color(skin["floor"].darkened(0.14), 0.35)
	var shadow_color := Color(0, 0, 0, 0.28)

	var ground_fan: PackedVector2Array
	match s:
		RoomExit.Side.LEFT:
			ground_fan = PackedVector2Array([
				Vector2(floor_rect.position.x, pos.y - half_w - 6),
				Vector2(floor_rect.position.x + 55, pos.y - half_w * 0.7),
				Vector2(floor_rect.position.x + 55, pos.y + half_w * 0.7),
				Vector2(floor_rect.position.x, pos.y + half_w + 6)
			])
			draw_line(Vector2(floor_rect.position.x, pos.y - half_w), Vector2(floor_rect.position.x, pos.y + half_w), shadow_color, 4.0)
		RoomExit.Side.RIGHT:
			ground_fan = PackedVector2Array([
				Vector2(floor_rect.end.x, pos.y - half_w - 6),
				Vector2(floor_rect.end.x - 55, pos.y - half_w * 0.7),
				Vector2(floor_rect.end.x - 55, pos.y + half_w * 0.7),
				Vector2(floor_rect.end.x, pos.y + half_w + 6)
			])
			draw_line(Vector2(floor_rect.end.x, pos.y - half_w), Vector2(floor_rect.end.x, pos.y + half_w), shadow_color, 4.0)
		RoomExit.Side.TOP:
			ground_fan = PackedVector2Array([
				Vector2(pos.x - half_w - 6, floor_rect.position.y),
				Vector2(pos.x - half_w * 0.7, floor_rect.position.y + 50),
				Vector2(pos.x + half_w * 0.7, floor_rect.position.y + 50),
				Vector2(pos.x + half_w + 6, floor_rect.position.y)
			])
			draw_line(Vector2(pos.x - half_w, floor_rect.position.y), Vector2(pos.x + half_w, floor_rect.position.y), shadow_color, 4.0)
		RoomExit.Side.BOTTOM:
			ground_fan = PackedVector2Array([
				Vector2(pos.x - half_w - 8, floor_rect.end.y),
				Vector2(pos.x - half_w * 0.7, floor_rect.end.y - (70 if is_town_mouth else 50)),
				Vector2(pos.x + half_w * 0.7, floor_rect.end.y - (70 if is_town_mouth else 50)),
				Vector2(pos.x + half_w + 8, floor_rect.end.y)
			])
			draw_line(Vector2(pos.x - half_w, floor_rect.end.y), Vector2(pos.x + half_w, floor_rect.end.y), shadow_color, 4.0)

	draw_colored_polygon(ground_fan, path_color)

	# 4. Environmental route hints on the floor.
	if dress == RoomExit.Presentation.CRYSTAL:
		# Crystalline sparkles on the path
		draw_circle(pos + Vector2(25, -15), 3.0, Color("8fe6cf", 0.6))
		draw_circle(pos + Vector2(35, 12), 2.5, Color("f1ffff", 0.7))
		draw_circle(pos + Vector2(15, 8), 2.0, Color("7fe0c4", 0.5))
	elif dress == RoomExit.Presentation.FRACTURED:
		# Threatening fracture lines branching from doorway into arena
		var c1 := PackedVector2Array([pos + Vector2(-5, -half_w), pos + Vector2(-30, -half_w - 15), pos + Vector2(-55, -half_w - 5)])
		var c2 := PackedVector2Array([pos + Vector2(-5, half_w), pos + Vector2(-35, half_w + 18), pos + Vector2(-65, half_w + 10)])
		draw_polyline(c1, Color("4b3d70", 0.8), 2.5, true)
		draw_polyline(c1, Color("a855f7", 0.5), 1.0, true)
		draw_polyline(c2, Color("4b3d70", 0.8), 2.5, true)
		draw_polyline(c2, Color("a855f7", 0.5), 1.0, true)
	elif is_town_mouth:
		# Worn sled tracks heading into the expedition mouth
		draw_line(pos + Vector2(-35, -45), pos + Vector2(-35, 10), Color(skin["rim"], 0.4), 2.0)
		draw_line(pos + Vector2(35, -45), pos + Vector2(35, 10), Color(skin["rim"], 0.4), 2.0)

## Draws a wall border line segment, splitting and bending outward at any doorway opening.
func _draw_wall_edge_with_doors(color: Color, width: float, start: Vector2, end: Vector2, side: int, is_horizontal_edge: bool) -> void:
	# Collect doorways on this side.
	var doors_on_side: Array[Dictionary] = []
	for door: Dictionary in doorways:
		if door.get("side", -1) == side:
			doors_on_side.append(door)

	if doors_on_side.is_empty():
		draw_line(start, end, color, width)
		return

	# Sort doors by coordinate along the edge.
	doors_on_side.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa: Vector2 = a.get("position", Vector2.ZERO)
		var pb: Vector2 = b.get("position", Vector2.ZERO)
		return (pa.x < pb.x) if is_horizontal_edge else (pa.y < pb.y)
	)

	var current_pos: Vector2 = start
	var return_dist: float = 14.0  # Bevel outward into the door frame

	for door: Dictionary in doors_on_side:
		var d_pos: Vector2 = door.get("position", Vector2.ZERO)
		var d_width: float = _get_door_width(door)
		var half_w: float = d_width * 0.5

		var door_start_pt: Vector2
		var door_end_pt: Vector2
		var jamb_out1: Vector2
		var jamb_out2: Vector2

		if is_horizontal_edge:
			door_start_pt = Vector2(d_pos.x - half_w, start.y)
			door_end_pt = Vector2(d_pos.x + half_w, start.y)
			var y_dir: float = -1.0 if side == RoomExit.Side.TOP else 1.0
			jamb_out1 = door_start_pt + Vector2(0, y_dir * return_dist)
			jamb_out2 = door_end_pt + Vector2(0, y_dir * return_dist)
		else:
			door_start_pt = Vector2(start.x, d_pos.y - half_w)
			door_end_pt = Vector2(start.x, d_pos.y + half_w)
			var x_dir: float = -1.0 if side == RoomExit.Side.LEFT else 1.0
			jamb_out1 = door_start_pt + Vector2(x_dir * return_dist, 0)
			jamb_out2 = door_end_pt + Vector2(x_dir * return_dist, 0)

		# Segment leading to door
		if current_pos.distance_to(door_start_pt) > 4.0:
			draw_line(current_pos, door_start_pt, color, width)

		# Bevel outward into door frame
		draw_line(door_start_pt, jamb_out1, color, width)
		# Bevel back from door frame
		draw_line(jamb_out2, door_end_pt, color, width)

		current_pos = door_end_pt

	# Final segment after last door
	if current_pos.distance_to(end) > 4.0:
		draw_line(current_pos, end, color, width)

func _draw_crystal(point: Vector2, skin: Dictionary) -> void:
	draw_set_transform(point)
	draw_colored_polygon(PackedVector2Array([Vector2(-18, 14), Vector2(-23, -18), Vector2(-10, -35), Vector2(0, -18), Vector2(7, -49), Vector2(21, -28), Vector2(20, 13)]), skin["crystal_dark"])
	draw_colored_polygon(PackedVector2Array([Vector2(-13, 8), Vector2(-18, -16), Vector2(-10, -28), Vector2(-2, -15), Vector2(0, 7)]), skin["crystal_mid"])
	draw_colored_polygon(PackedVector2Array([Vector2(1, 7), Vector2(10, -40), Vector2(17, -26), Vector2(15, 8)]), skin["crystal_light"])
	draw_line(Vector2(10, -40), Vector2(7, 6), skin["crystal_edge"], 2)
	draw_set_transform(Vector2.ZERO)
