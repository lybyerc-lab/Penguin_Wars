extends Node2D
## Seeded decorative art only. Does not define collisions or spawn positions.
func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 92
	draw_rect(Rect2(-1500, -1000, 3000, 2000), Color("102d44"))
	for index: int in range(90):
		var point := Vector2(rng.randf_range(-900, 900), rng.randf_range(-600, 600))
		draw_line(point, point + Vector2(rng.randf_range(12, 55), 0), Color("1e4058"), 2)
	var edge := StyleBoxFlat.new()
	edge.bg_color = Color("214559")
	edge.set_corner_radius_all(48)
	draw_style_box(edge, Rect2(-590, -280, 1180, 600))
	edge.bg_color = Color("80bac9")
	draw_style_box(edge, Rect2(-584, -299, 1168, 594))
	edge.bg_color = Color("397487")
	edge.border_color = Color("c0e4e2")
	edge.set_border_width_all(12)
	draw_style_box(edge, Rect2(-575, -300, 1150, 585))
	for index: int in range(55):
		var point := Vector2(rng.randf_range(-530, 530), rng.randf_range(-245, 240))
		draw_circle(point, rng.randf_range(2, 6), Color(0.7, 0.94, 0.96, 0.10))
	# Sparse angular cracks keep the combat floor readable.
	for origin: Vector2 in [Vector2(-480, -180), Vector2(300, 170), Vector2(-370, 170), Vector2(470, -110)]:
		var points := PackedVector2Array([origin, origin + Vector2(50, 15), origin + Vector2(80, -12), origin + Vector2(125, 7)])
		draw_polyline(points, Color("2d6177"), 3, true)
		draw_polyline(points, Color(0.6, 0.88, 0.95, 0.22), 1, true)
		draw_line(origin + Vector2(50, 15), origin + Vector2(55, 48), Color("2d6177"), 2)
	draw_arc(Vector2.ZERO, 90, 0, TAU, 64, Color(0.7, 0.95, 1, 0.12), 3)
	draw_arc(Vector2.ZERO, 100, 0, TAU, 64, Color(0.7, 0.95, 1, 0.08), 1)
	for point: Vector2 in [Vector2(-563, -234), Vector2(-567, 215), Vector2(560, -211), Vector2(553, 246), Vector2(-355, 282), Vector2(371, -285)]:
		_draw_crystal(point)
	for point: Vector2 in [Vector2(-470, -277), Vector2(200, 272), Vector2(470, 281), Vector2(-170, -282)]:
		draw_set_transform(point, 0, Vector2(1, 0.35))
		draw_circle(Vector2.ZERO, 26, Color("a2ced7"))
		draw_circle(Vector2(-3, -5), 21, Color("e1f0e9"))
	draw_set_transform(Vector2.ZERO)

func _draw_crystal(point: Vector2) -> void:
	draw_set_transform(point)
	draw_colored_polygon(PackedVector2Array([Vector2(-18, 14), Vector2(-23, -18), Vector2(-10, -35), Vector2(0, -18), Vector2(7, -49), Vector2(21, -28), Vector2(20, 13)]), Color("183e58"))
	draw_colored_polygon(PackedVector2Array([Vector2(-13, 8), Vector2(-18, -16), Vector2(-10, -28), Vector2(-2, -15), Vector2(0, 7)]), Color("7bc9d8"))
	draw_colored_polygon(PackedVector2Array([Vector2(1, 7), Vector2(10, -40), Vector2(17, -26), Vector2(15, 8)]), Color("b4e9e9"))
	draw_line(Vector2(10, -40), Vector2(7, 6), Color("f1ffff"), 2)
	draw_set_transform(Vector2.ZERO)
