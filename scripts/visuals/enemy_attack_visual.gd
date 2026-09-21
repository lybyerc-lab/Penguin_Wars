extends Node2D
## Warnings and role silhouettes read behavior state; they cannot cause damage.
var _enemy: ArenaEnemy
var _time: float = 0.0

func _ready() -> void:
	_enemy = get_parent() as ArenaEnemy

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	if _enemy == null or not _enemy.health.is_alive():
		return
	var charge := _enemy.behavior as ChargeBehavior
	if charge != null:
		# Wide armored brow distinguishes chargers without relying on tint alone.
		draw_colored_polygon(PackedVector2Array([Vector2(-24, -24), Vector2(-16, -36), Vector2(16, -36), Vector2(24, -24)]), Color("f2a66c"))
		draw_line(Vector2(-18, -25), Vector2(18, -25), Color("623f50"), 4)
		if charge.state == ChargeBehavior.State.WINDUP:
			var length: float = charge.charge_speed * charge.charge_time
			var perpendicular := charge.direction.orthogonal() * 20.0
			var end: Vector2 = charge.direction * length
			draw_colored_polygon(PackedVector2Array([perpendicular, end + perpendicular, end - perpendicular, -perpendicular]), Color(1, 0.49, 0.29, 0.19))
			draw_line(perpendicular, end + perpendicular, Color("ffb47d"), 2)
			draw_line(-perpendicular, end - perpendicular, Color("ffb47d"), 2)
			draw_line(end + perpendicular, end, Color("ffdc9f"), 3)
			draw_line(end - perpendicular, end, Color("ffdc9f"), 3)
		elif charge.state == ChargeBehavior.State.RECOVER:
			draw_arc(Vector2(0, -44), 10, _time * 4, _time * 4 + 4, 16, Color("ffd49c"), 2)
		return
	var ranged := _enemy.behavior as RangedBehavior
	if ranged != null:
		# Blue winter cap, pompom and a held snowball mark the ranged silhouette.
		draw_arc(Vector2(0, -23), 18, PI, TAU, 20, Color("89c5ed"), 9)
		draw_circle(Vector2(0, -45), 6, Color("effbff"))
		draw_circle(Vector2(24, -3), 9, Color("eefaff"))
		if ranged.state == RangedBehavior.State.WINDUP:
			for distance: int in range(30, 270, 18):
				draw_line(ranged.direction * distance, ranged.direction * (distance + 8), Color(0.79, 0.93, 1, 0.7), 2)
			draw_arc(Vector2(24, -3), 13, 0, TAU * (1.0 - ranged.remaining / ranged.windup_time), 24, Color("83d9ff"), 3)
