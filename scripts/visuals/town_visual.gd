class_name TownVisual
extends Node2D
## Minimal peaceful staging area. Buildings are decorative until services land.
func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	for index: int in range(3):
		var point := Vector2((index - 1) * 280, -150)
		draw_circle(point + Vector2(0, 40), 102, Color("92bac8"))
		var body := Rect2(point + Vector2(-85, -60), Vector2(170, 120))
		var style := StyleBoxFlat.new()
		style.bg_color = Color("d2e9e7")
		style.set_corner_radius_all(25)
		draw_style_box(style, body)
		draw_colored_polygon(PackedVector2Array([point + Vector2(-102, -45), point + Vector2(0, -122), point + Vector2(102, -45)]), Color("7597ae"))
		draw_polyline(PackedVector2Array([point + Vector2(-106, -50), point + Vector2(0, -130), point + Vector2(106, -50)]), Color("f2ffff"), 12, true)
		draw_rect(Rect2(point + Vector2(-20, 0), Vector2(40, 60)), Color("244457"))
		for side: int in [-1, 1]:
			draw_rect(Rect2(point + Vector2(side * 52 - 13, -17), Vector2(26, 30)), Color("ffd98c"))
		var title: String = ["NURSE", "TOWN HALL", "BLACKSMITH"][index]
		draw_string(font, point + Vector2(-100, 90), title, HORIZONTAL_ALIGNMENT_CENTER, 200, 20, Color("ffffff"))
		draw_string(font, point + Vector2(-100, 110), "Coming soon", HORIZONTAL_ALIGNMENT_CENTER, 200, 14, Color("cce9ee"))
