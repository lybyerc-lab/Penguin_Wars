class_name TownshipV01
extends Node2D
## Playable Godot translation of the locked Township V0.2 Blender blockout.
## Coordinates and landmark relationships are intentionally local to this
## one town. This is a runtime blockout, not an environment-import pipeline.

const WORLD_BOUNDS := Rect2(-1260, -1200, 2520, 2800)
const SPAWN_POINT := Vector2(0, 250)
const DEPARTURE_GATE := Vector2(64, 835)
const DEPARTURE_BOUNDARY := Vector2(570, 1600)
const SLIDE_CENTER := Vector2(-875, 120)
const SLIDE_SIZE := Vector2(220, 540)

const GREAT_HALL := Rect2(-316, -975, 720, 432)
const WORKSHOP := Rect2(-912, -484, 392, 323)
const HOME_A := Rect2(-827, 361, 300, 253)
const HOME_B := Rect2(-591, 637, 253, 230)
const FISH_SHED := Rect2(869, -349, 184, 265)
const NET_SHED := Rect2(574, 180, 230, 196)
const LODGE := Rect2(374, 585, 403, 334)
const MARKET_COUNTER := Rect2(507, -104, 334, 52)
const PRODUCTION_BACKGROUND := "res://assets/environments/township_visual_v1/township_background.png"

const MARKET_POSTS: Array[Vector2] = [
	Vector2(499, -4), Vector2(863, -61), Vector2(463, -231), Vector2(827, -289),
]

## Deliberately local presentation regions for Township V1. They do not alter
## collision or movement: CharacterVisual reads the level per player and lifts
## only its visual pivot while the gameplay root stays on the 2D ground plane.
const ELEVATION_META: StringName = &"township_elevation_level"
const ELEVATION_REGIONS: Array[Dictionary] = [
	{"id": &"great_hall_steps", "bounds": Rect2(-205, -550, 500, 200), "level": 2},
	{"id": &"workshop_terrace", "bounds": Rect2(-945, -250, 460, 220), "level": 2},
	{"id": &"town_square", "bounds": Rect2(-430, -350, 860, 680), "level": 1},
]

var party: PartyRoster

static func build(into: Node2D, roster: PartyRoster) -> TownshipV01:
	var township := TownshipV01.new()
	township.name = "TownshipV01"
	township.party = roster
	into.add_child(township)
	return township

func _ready() -> void:
	z_index = -8
	_build_collision()
	_build_slide()
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if party == null:
		return
	for player: PenguinPlayer in party.members():
		player.set_meta(ELEVATION_META, elevation_level_at(player.global_position))

func elevation_level_at(position: Vector2) -> int:
	for region: Dictionary in ELEVATION_REGIONS:
		if (region["bounds"] as Rect2).has_point(position):
			return int(region["level"])
	return 0

func elevation_region_at(position: Vector2) -> StringName:
	for region: Dictionary in ELEVATION_REGIONS:
		if (region["bounds"] as Rect2).has_point(position):
			return region["id"] as StringName
	return &"base_ground"

func _exit_tree() -> void:
	if party == null:
		return
	for player: PenguinPlayer in party.members():
		player.remove_meta(ELEVATION_META)

func _build_collision() -> void:
	_add_blocker("GreatHallCollision", GREAT_HALL.grow(-10.0))
	_add_blocker("WorkshopCollision", Rect2(-914, -487, 397, 327))
	_add_blocker("WorkshopWestAnnexCollision", Rect2(-970, -369, 52, 75))
	# Mobile review showed the old doorway notch let players enter the approved
	# Nurse footprint. Keep the south-facing service pad outside the solid hut.
	_add_blocker("HomeACollision", Rect2(-827, 361, 299, 253))
	_add_blocker("HomeBCollision", HOME_B.grow(-8.0))
	_add_blocker("FishShedCollision", FISH_SHED.grow(-6.0))
	_add_blocker("NetShedCollision", NET_SHED.grow(-6.0))
	_add_blocker("LodgeCollision", LODGE.grow(-8.0))
	_add_polygon_blocker("FishersStallCollision", PackedVector2Array([
		Vector2(437, -250), Vector2(479, 20), Vector2(888, -43), Vector2(846, -312),
	]))
	_add_blocker("SlideDeckCollision", Rect2(-1115, -190, 169, 119))
	_add_circle_blocker("BellCollision", Vector2(232, 536), 58.0)
	_add_blocker("DepartureGateLeft", Rect2(DEPARTURE_GATE + Vector2(-190, -62), Vector2(42, 124)))
	_add_blocker("DepartureGateRight", Rect2(DEPARTURE_GATE + Vector2(148, -62), Vector2(42, 124)))

func _add_blocker(node_name: String, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.get_center()
	body.add_child(collision)
	add_child(body)

func _add_polygon_blocker(node_name: String, points: PackedVector2Array) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionPolygon2D.new()
	collision.polygon = points
	body.add_child(collision)
	add_child(body)

func _add_circle_blocker(node_name: String, center: Vector2, radius: float) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	collision.position = center
	body.add_child(collision)
	add_child(body)

func _build_slide() -> void:
	var slide := TownshipSnowSlide.new()
	slide.name = "SnowSlide"
	slide.position = SLIDE_CENTER
	slide.rotation = -0.16
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SLIDE_SIZE
	collision.shape = shape
	# Start the active chute south of the raised launch deck. The old centered
	# Area began under the deck and made the penguin slide while visually hidden.
	collision.position = Vector2(0, 90)
	slide.add_child(collision)
	add_child(slide)

func _draw() -> void:
	# Keep the original procedural blockout as a missing-asset fallback. The
	# production plate is otherwise the sole Township environment presentation.
	if ResourceLoader.exists(PRODUCTION_BACKGROUND):
		return
	# Ground and the broad, curved routes from the locked blockout.
	# Paint past the movement clamp so the follow camera never exposes the
	# clear color at the outer landmarks.
	draw_rect(WORLD_BOUNDS.grow(720.0), Color("c7e6ef"))
	_draw_snow_banks()
	_draw_route(PackedVector2Array([Vector2(-760, -300), Vector2(-520, -180), Vector2(-330, -60), Vector2(-100, 0)]), 150.0)
	_draw_route(PackedVector2Array([Vector2(0, -560), Vector2(0, -330), Vector2(0, -50)]), 170.0)
	_draw_route(PackedVector2Array([Vector2(330, -50), Vector2(570, -30), Vector2(760, 80)]), 145.0)
	_draw_route(PackedVector2Array([Vector2(0, 300), Vector2(35, 610), DEPARTURE_GATE, Vector2(150, 1080), Vector2(350, 1320), DEPARTURE_BOUNDARY]), 170.0)
	_draw_elevation_layers()

	# Central 11 x 9.2 metre gathering square.
	var square := Rect2(-446, -368, 892, 736)
	draw_rect(Rect2(square.position + Vector2(0, 16), square.size), Color("6f9fac", 0.55))
	draw_rect(square.grow(22.0), Color("9fcbd9"))
	draw_rect(square, Color("d9eff4"))
	for x: float in range(-400, 401, 100):
		draw_line(Vector2(x, square.position.y), Vector2(x + 35, square.end.y), Color("bddce5", 0.55), 2.0)
	for y: float in range(-320, 321, 80):
		draw_line(Vector2(square.position.x, y), Vector2(square.end.x, y), Color("eef9fb", 0.65), 2.0)
	draw_line(Vector2(square.position.x, square.end.y), square.end, Color("7facb9"), 10.0)
	draw_string(ThemeDB.fallback_font, Vector2(-115, 20), "TOWNSHIP SQUARE", HORIZONTAL_ALIGNMENT_CENTER, 230, 15, Color("577888"))

	_draw_building(GREAT_HALL, Color("678fb1"), "GREAT HALL", &"none")
	_draw_hall_steps()
	_draw_building(WORKSHOP, Color("c98b5a"), "WORKSHOP", &"south")
	_draw_building(HOME_A, Color("77a6a1"), "HOME", &"east")
	_draw_building(HOME_B, Color("8c87ad"), "HOME", &"north")
	_draw_building(FISH_SHED, Color("5f8ca0"), "FISH SHED", &"west")
	_draw_building(NET_SHED, Color("6d9d8c"), "NET SHED", &"west")
	_draw_building(LODGE, Color("b77868"), "LODGE", &"north")
	_draw_market()
	_draw_pond()
	_draw_slide()
	_draw_bell()
	_draw_departure_gate()
	_draw_future_edges()

func _draw_snow_banks() -> void:
	var bank := Color("e7f5f7")
	for point: Vector2 in [Vector2(-1100, -850), Vector2(-850, -1010), Vector2(850, -960), Vector2(1090, -650), Vector2(-1090, 900), Vector2(1030, 1030), Vector2(-700, 1500)]:
		draw_circle(point, 190.0, bank)
		draw_arc(point, 190.0, 0.0, TAU, 40, Color("acd4df"), 5.0)

func _draw_route(points: PackedVector2Array, width: float) -> void:
	draw_polyline(points, Color("a8ced8"), width + 20.0, true)
	draw_polyline(points, Color("e4f2f4"), width, true)
	draw_polyline(points, Color("f8fdfe", 0.7), 4.0, true)

func _draw_elevation_layers() -> void:
	# Shallow local platforms create hierarchy without changing traversal.
	_draw_terrace(GREAT_HALL.grow(42.0), 24.0, Color("c3dfe6"))
	_draw_terrace(WORKSHOP.grow(38.0), 14.0, Color("d4e9eb"))
	_draw_terrace(HOME_A.grow(30.0), 11.0, Color("d1e8ea"))
	_draw_terrace(HOME_B.grow(30.0), 11.0, Color("d1e8ea"))

	# The east market/pond district sits in a broad, subtly lower basin.