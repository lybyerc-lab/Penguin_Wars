extends Node2D
## Decorative floor stretches to the room edges; gameplay uses the same room size.
var floor_rect := Rect2(-640, -360, 1280, 720)

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 92
	draw_rect(floor_rect.grow(100), Color("397487"))
	for index: int in range(120):
		var point := Vector2(rng.randf_range(floor_rect.position.x, floor_rect.end.x), rng.randf_range(floor_rect.position.y, floor_rect.end.y))
		draw_circle(point, rng.randf_range(2, 6), Color(0.7, 0.94, 0.96, 0.10))
	for index: int in range(12):
		var origin := Vector2(rng.randf_range(floor_rect.position.x, floor_rect.end.x), rng.randf_range(floor_rect.position.y, floor_rect.end.y))
		var points := PackedVector2Array([origin, origin + Vector2(50, 15), origin + Vector2(80, -12), origin + Vector2(125, 7)])
		draw_polyline(points, Color("2d6177"), 3, true)
		draw_polyline(points, Color(0.6, 0.88, 0.95, 0.18), 1, true)
		draw_line(origin + Vector2(50, 15), origin + Vector2(55, 48), Color("2d6177"), 2)
	draw_arc(Vector2.ZERO, 90, 0, TAU, 64, Color(0.7, 0.95, 1, 0.10), 3)
	draw_arc(Vector2.ZERO, 100, 0, TAU, 64, Color(0.7, 0.95, 1, 0.07), 1)
