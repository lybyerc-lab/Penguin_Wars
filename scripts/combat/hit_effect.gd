class_name HitEffect
extends Node2D
## Short-lived world-space feedback survives the defeated actor.
var amount: float
var tint: Color = Color("baf9ff")
var lethal: bool = false
var _age: float = 0.0

func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= 0.45:
		queue_free()

func _draw() -> void:
	var fade := Color(tint, 1.0 - _age / 0.45)
	var radius: float = 8.0 + _age * (95.0 if lethal else 50.0)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 24, fade, 2.0)
	for index: int in range(6):
		var direction := Vector2.from_angle(index * TAU / 6)
		draw_line(direction * radius, direction * (radius + 5), fade, 2)
	draw_string(ThemeDB.fallback_font, Vector2(-8, -22 - _age * 48), str(int(amount)), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, fade)
