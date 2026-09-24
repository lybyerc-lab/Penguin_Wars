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

const MARKET_POSTS: Array[Vector2] = [
	Vector2(499, -4), Vector2(863, -61), Vector2(463, -231), Vector2(827, -289),
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

func _build_collision() -> void:
	_add_blocker("GreatHallCollision", GREAT_HALL.grow(-10.0))
	_add_blocker("WorkshopCollision", WORKSHOP.grow(-8.0))
	_add_blocker("HomeACollision", HOME_A.grow(-8.0))
	_add_blocker("HomeBCollision", HOME_B.grow(-8.0))
	_add_blocker("FishShedCollision", FISH_SHED.grow(-6.0))
	_add_blocker("NetShedCollision", NET_SHED.grow(-6.0))
	_add_blocker("LodgeCollision", LODGE.grow(-8.0))
	_add_blocker("MarketCounterCollision", MARKET_COUNTER)
	# The four slender market canopy posts stay visual-only. A broad counter
	# collision preserves the stall mass without snagging player shoulders.
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

func _build_slide() -> void:
	var slide := TownshipSnowSlide.new()
	slide.name = "SnowSlide"
	slide.position = SLIDE_CENTER
	slide.rotation = -0.16
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SLIDE_SIZE
	collision.shape = shape
	slide.add_child(collision)
	add_child(slide)

func _draw() -> void:
	# Ground and the broad, curved routes from the locked blockout.
	# Paint past the movement clamp so the follow camera never exposes the
	# clear color at the outer landmarks.
	draw_rect(WORLD_BOUNDS.grow(720.0), Color("c7e6ef"))
	_draw_snow_banks()
	_draw_route(PackedVector2Array([Vector2(-760, -300), Vector2(-520, -180), Vector2(-330, -60), Vector2(-100, 0)]), 150.0)
	_draw_route(PackedVector2Array([Vector2(0, -560), Vector2(0, -330), Vector2(0, -50)]), 170.0)
	_draw_route(PackedVector2Array([Vector2(330, -50), Vector2(570, -30), Vector2(760, 80)]), 145.0)
	_draw_route(PackedVector2Array([Vector2(0, 300), Vector2(35, 610), DEPARTURE_GATE, Vector2(150, 1080), Vector2(350, 1320), DEPARTURE_BOUNDARY]), 170.0)

	# Central 11 x 9.2 metre gathering square.
	var square := Rect2(-446, -368, 892, 736)
	draw_rect(square.grow(22.0), Color("9fcbd9"))
	draw_rect(square, Color("d9eff4"))
	for x: float in range(-400, 401, 100):
		draw_line(Vector2(x, square.position.y), Vector2(x + 35, square.end.y), Color("bddce5", 0.55), 2.0)
	for y: float in range(-320, 321, 80):
		draw_line(Vector2(square.position.x, y), Vector2(square.end.x, y), Color("eef9fb", 0.65), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-115, 20), "TOWNSHIP SQUARE", HORIZONTAL_ALIGNMENT_CENTER, 230, 15, Color("577888"))

	_draw_building(GREAT_HALL, Color("678fb1"), "GREAT HALL")
	_draw_hall_steps()
	_draw_building(WORKSHOP, Color("c98b5a"), "WORKSHOP")
	_draw_building(HOME_A, Color("77a6a1"), "HOME")
	_draw_building(HOME_B, Color("8c87ad"), "HOME")
	_draw_building(FISH_SHED, Color("5f8ca0"), "FISH SHED")
	_draw_building(NET_SHED, Color("6d9d8c"), "NET SHED")
	_draw_building(LODGE, Color("b77868"), "LODGE")
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

func _draw_building(rect: Rect2, roof: Color, label: String) -> void:
	draw_rect(Rect2(rect.position + Vector2(14, 17), rect.size), Color("29465a", 0.22))
	draw_rect(rect, Color("d5e7ea"))
	var cap := rect.grow(13.0)
	draw_rect(cap, roof)
	draw_rect(cap, roof.lightened(0.23), false, 6.0)
	for y: float in range(int(rect.position.y + 34), int(rect.end.y), 42):
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color("afc9cf", 0.55), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.get_center().y + 6), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 17, Color("183445"))

func _draw_hall_steps() -> void:
	for index: int in range(4):
		var width: float = 300.0 + index * 38.0
		draw_rect(Rect2(Vector2(44 - width * 0.5, -543 + index * 22), Vector2(width, 20)), Color("b6d3dc").lightened(index * 0.035))
	draw_rect(Rect2(-36, -565, 160, 48), Color("314f62"))

func _draw_market() -> void:
	var canopy := PackedVector2Array([Vector2(455, -315), Vector2(875, -315), Vector2(835, -135), Vector2(495, -135)])
	draw_colored_polygon(canopy, Color("e5a85c"))
	draw_polyline(canopy, Color("fff0c7"), 5.0, true)
	draw_rect(MARKET_COUNTER, Color("79513e"))
	draw_rect(MARKET_COUNTER, Color("c58a58"), false, 5.0)
	for post: Vector2 in MARKET_POSTS:
		draw_circle(post, 11.0, Color("684636"))
		draw_circle(post, 6.0, Color("a87955"))
	draw_string(ThemeDB.fallback_font, Vector2(490, -170), "FISH MARKET", HORIZONTAL_ALIGNMENT_CENTER, 360, 17, Color("513522"))

func _draw_pond() -> void:
	var center := Vector2(940, 430)
	draw_set_transform(center, 0.0, Vector2(1.45, 0.78))
	draw_circle(Vector2.ZERO, 120.0, Color("6bbbd1"))
	draw_arc(Vector2.ZERO, 120.0, 0, TAU, 48, Color("e8fbff"), 8.0)
	draw_circle(Vector2(-18, 6), 35.0, Color("295f7a"))
	draw_set_transform(Vector2.ZERO)
	draw_string(ThemeDB.fallback_font, Vector2(830, 445), "FISHING POND", HORIZONTAL_ALIGNMENT_CENTER, 220, 14, Color("285b70"))

func _draw_slide() -> void:
	var chute := PackedVector2Array([Vector2(-1035, -170), Vector2(-870, -220), Vector2(-725, 360), Vector2(-940, 400)])
	draw_colored_polygon(chute, Color("edf9fb"))
	draw_polyline(chute, Color("74b8cc"), 9.0, true)
	for y: float in [-80.0, 40.0, 160.0, 280.0]:
		draw_line(Vector2(-980 + y * 0.07, y), Vector2(-790 + y * 0.05, y + 22), Color("b5dce6"), 5.0)
	draw_string(ThemeDB.fallback_font, Vector2(-1050, -245), "SNOW SLIDE", HORIZONTAL_ALIGNMENT_CENTER, 330, 16, Color("3d7082"))

func _draw_bell() -> void:
	var at := Vector2(232, 536)
	draw_line(at + Vector2(-42, 52), at + Vector2(-28, -48), Color("77543d"), 13.0)
	draw_line(at + Vector2(42, 52), at + Vector2(28, -48), Color("77543d"), 13.0)
	draw_line(at + Vector2(-34, -42), at + Vector2(34, -42), Color("9b6d48"), 12.0)
	draw_circle(at + Vector2(0, -10), 28.0, Color("d5a33f"))
	draw_string(ThemeDB.fallback_font, at + Vector2(-60, 78), "BELL", HORIZONTAL_ALIGNMENT_CENTER, 120, 14, Color("69502e"))

func _draw_departure_gate() -> void:
	var timber := Color("6b4934")
	for x: float in [DEPARTURE_GATE.x - 170.0, DEPARTURE_GATE.x + 170.0]:
		draw_rect(Rect2(x - 19, DEPARTURE_GATE.y - 82, 38, 164), timber)
		draw_rect(Rect2(x - 24, DEPARTURE_GATE.y - 88, 48, 18), Color("b5dce4"))
	draw_line(DEPARTURE_GATE + Vector2(-170, -70), DEPARTURE_GATE + Vector2(170, -70), Color("8a6040"), 25.0)
	draw_string(ThemeDB.fallback_font, DEPARTURE_GATE + Vector2(-155, -92), "DEPARTURE GATE", HORIZONTAL_ALIGNMENT_CENTER, 310, 18, Color("273f4d"))
	draw_rect(Rect2(DEPARTURE_BOUNDARY + Vector2(-180, -28), Vector2(360, 56)), Color("73a9b8", 0.35))
	draw_line(DEPARTURE_BOUNDARY + Vector2(-180, 0), DEPARTURE_BOUNDARY + Vector2(180, 0), Color("dff7fb"), 5.0)
	draw_string(ThemeDB.fallback_font, DEPARTURE_BOUNDARY + Vector2(-190, -44), "FROZEN COAST — EXPEDITION BOUNDARY", HORIZONTAL_ALIGNMENT_CENTER, 380, 14, Color("315968"))

func _draw_future_edges() -> void:
	_draw_blocked_marker(Vector2(-1040, -760), "BLOCKED RIDGE")
	_draw_blocked_marker(Vector2(980, -720), "FUTURE BRIDGE")
	var plot := Rect2(-1110, 1080, 360, 250)
	draw_rect(plot, Color("d8edf1", 0.75))
	draw_rect(plot, Color("7394a2", 0.65), false, 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(plot.position.x, plot.get_center().y), "FUTURE BUILD PLOT", HORIZONTAL_ALIGNMENT_CENTER, plot.size.x, 15, Color("607985"))

func _draw_blocked_marker(at: Vector2, text: String) -> void:
	draw_line(at + Vector2(-90, -30), at + Vector2(90, 30), Color("8a6250"), 16.0)
	draw_line(at + Vector2(-90, 30), at + Vector2(90, -30), Color("8a6250"), 16.0)
	draw_string(ThemeDB.fallback_font, at + Vector2(-120, 65), text, HORIZONTAL_ALIGNMENT_CENTER, 240, 14, Color("6b4a3b"))
