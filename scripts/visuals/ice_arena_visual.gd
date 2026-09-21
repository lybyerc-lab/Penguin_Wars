class_name RoomVisual
extends Node2D
## Seeded decorative art only. Does not define collisions or spawn positions.
## Every shape is derived from the room bounds, so one script dresses the
## original ice arena and any later cave room at its own size.
## Doorway openings are drawn as gaps in the wall where PartyGates sit.

## Palettes are indexed by RoomDefinition.Palette.
const PALETTES: Array[Dictionary] = [
	{
		"backdrop": Color("102d44"), "streak": Color("1e4058"), "rim": Color("214559"),
		"shelf": Color("80bac9"), "floor": Color("397487"), "border": Color("c0e4e2"),
		"speck": Color(0.7, 0.94, 0.96, 0.10), "crack": Color("2d6177"),
		"crack_light": Color(0.6, 0.88, 0.95, 0.22), "ring": Color(0.7, 0.95, 1.0, 1.0),
		"crystal_dark": Color("183e58"), "crystal_mid": Color("7bc9d8"),
		"crystal_light": Color("b4e9e9"), "crystal_edge": Color("f1ffff"),
		"drift_dark": Color("a2ced7"), "drift_light": Color("e1f0e9"),
		"passage": Color("0a1218"),
	},
	{
		"backdrop": Color("161127"), "streak": Color("241d3d"), "rim": Color("2a2140"),
		"shelf": Color("6b5a86"), "floor": Color("3c3357"), "border": Color("9d8bc0"),
		"speck": Color(0.85, 0.78, 1.0, 0.10), "crack": Color("4b3d70"),
		"crack_light": Color(0.78, 0.68, 0.98, 0.22), "ring": Color(0.85, 0.78, 1.0, 1.0),
		"crystal_dark": Color("2a1f42"), "crystal_mid": Color("8f7bc9"),
		"crystal_light": Color("c3b0e9"), "crystal_edge": Color("f4ecff"),
		"drift_dark": Color("6d5f8c"), "drift_light": Color("cdbde8"),
		"passage": Color("0a0815"),
	},
	{
		"backdrop": Color("0a1620"), "streak": Color("12303c"), "rim": Color("163445"),
		"shelf": Color("3f8f8c"), "floor": Color("1d4b52"), "border": Color("68c9b6"),
		"speck": Color(0.6, 1.0, 0.92, 0.10), "crack": Color("205f60"),
		"crack_light": Color(0.5, 0.95, 0.85, 0.22), "ring": Color(0.6, 1.0, 0.92, 1.0),
		"crystal_dark": Color("10303a"), "crystal_mid": Color("3fae9d"),
		"crystal_light": Color("8fe6cf"), "crystal_edge": Color("e8fff8"),
		"drift_dark": Color("3e7f80"), "drift_light": Color("bfe8dd"),
		"passage": Color("060f16"),
	},
]

## Fractions of the bounds half-extents. Values above 1.0 sit on the rim.
const CRACKS: Array[Vector2] = [Vector2(-0.8889, -0.6923), Vector2(0.5556, 0.6538), Vector2(-0.6852, 0.6538), Vector2(0.8704, -0.4231)]
const CRYSTALS: Array[Vector2] = [Vector2(-1.0426, -0.9), Vector2(-1.05, 0.8269), Vector2(1.037, -0.8115), Vector2(1.0241, 0.9462), Vector2(-0.6574, 1.0846), Vector2(0.687, -1.0962)]
const DRIFTS: Array[Vector2] = [Vector2(-0.8704, -1.0654), Vector2(0.3704, 1.0462), Vector2(0.8704, 1.0808), Vector2(-0.3148, -1.0846)]

## Width of a doorway opening in the wall. Matches PartyGate.THRESHOLD_WIDTH.
const DOORWAY_WIDTH: float = 130.0

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

## Doorway data set by the room setup. Each entry is {side: int, position: Vector2}.
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
	draw_rect(Rect2(center - Vector2(1500, 1000), Vector2(3000, 2000)), skin["backdrop"])
	for index: int in range(90):
		var point := center + Vector2(rng.randf_range(-900, 900), rng.randf_range(-600, 600))
		draw_line(point, point + Vector2(rng.randf_range(12, 55), 0), skin["streak"], 2)
	# The floor is the bounds plus a lip, so actors never stand on the painted wall.
	var floor_rect: Rect2 = bounds.grow_individual(35, 40, 35, 25)
	var edge := StyleBoxFlat.new()
	edge.bg_color = skin["rim"]
	edge.set_corner_radius_all(48)
	draw_style_box(edge, floor_rect.grow_individual(15, -20, 15, 35))
	edge.bg_color = skin["shelf"]
	draw_style_box(edge, floor_rect.grow_individual(9, -1, 9, 10))
	edge.bg_color = skin["floor"]
	edge.border_color = skin["border"]
	edge.set_border_width_all(12)
	draw_style_box(edge, floor_rect)
	# Draw doorway openings in the wall.
	_draw_doorways(skin, floor_rect)
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

func _draw_doorways(skin: Dictionary, floor_rect: Rect2) -> void:
	var passage_color: Color = skin.get("passage", skin["backdrop"])
	for door: Dictionary in doorways:
		var s: int = door.get("side", RoomExit.Side.BOTTOM)
		var pos: Vector2 = door.get("position", bounds.get_center())
		var half_w: float = DOORWAY_WIDTH * 0.5
		# Cut a dark passage rectangle through the wall layers.
		var opening: Rect2
		var depth: float = 60.0  # How deep the opening extends through the wall.
		match s:
			RoomExit.Side.LEFT:
				opening = Rect2(floor_rect.position.x - 20, pos.y - half_w, depth + 20, DOORWAY_WIDTH)
			RoomExit.Side.RIGHT:
				opening = Rect2(floor_rect.end.x - depth, pos.y - half_w, depth + 20, DOORWAY_WIDTH)
			RoomExit.Side.TOP:
				opening = Rect2(pos.x - half_w, floor_rect.position.y - 20, DOORWAY_WIDTH, depth + 20)
			RoomExit.Side.BOTTOM:
				opening = Rect2(pos.x - half_w, floor_rect.end.y - depth, DOORWAY_WIDTH, depth + 20)
		draw_rect(opening, passage_color)
		# Subtle edge highlight on the doorway frame.
		var edge_color := Color(skin["border"], 0.5)
		match s:
			RoomExit.Side.LEFT, RoomExit.Side.RIGHT:
				draw_line(Vector2(opening.position.x, opening.position.y),
						  Vector2(opening.end.x, opening.position.y), edge_color, 2)
				draw_line(Vector2(opening.position.x, opening.end.y),
						  Vector2(opening.end.x, opening.end.y), edge_color, 2)
			RoomExit.Side.TOP, RoomExit.Side.BOTTOM:
				draw_line(Vector2(opening.position.x, opening.position.y),
						  Vector2(opening.position.x, opening.end.y), edge_color, 2)
				draw_line(Vector2(opening.end.x, opening.position.y),
						  Vector2(opening.end.x, opening.end.y), edge_color, 2)

func _draw_crystal(point: Vector2, skin: Dictionary) -> void:
	draw_set_transform(point)
	draw_colored_polygon(PackedVector2Array([Vector2(-18, 14), Vector2(-23, -18), Vector2(-10, -35), Vector2(0, -18), Vector2(7, -49), Vector2(21, -28), Vector2(20, 13)]), skin["crystal_dark"])
	draw_colored_polygon(PackedVector2Array([Vector2(-13, 8), Vector2(-18, -16), Vector2(-10, -28), Vector2(-2, -15), Vector2(0, 7)]), skin["crystal_mid"])
	draw_colored_polygon(PackedVector2Array([Vector2(1, 7), Vector2(10, -40), Vector2(17, -26), Vector2(15, 8)]), skin["crystal_light"])
	draw_line(Vector2(10, -40), Vector2(7, 6), skin["crystal_edge"], 2)
	draw_set_transform(Vector2.ZERO)
