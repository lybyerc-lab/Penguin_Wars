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
			draw_colored_polygon(PackedVector2Array([perpendicular, end + perpendicular, end - perpendicular, -perpendicular]), Color(1, 0.49, 0.29, 0.13))
			draw_line(perpendicular, end + perpendicular, Color("ff8d6a", 0.88), 2.5)
			draw_line(-perpendicular, end - perpendicular, Color("ff8d6a", 0.88), 2.5)
			if charge.crash_on_world_collision:
				# Tuskbull V1: amber direction chevrons and snow streaks inside a
				# translucent lane. Never a giant opaque arrow over the player.
				for fraction: float in [0.30, 0.55, 0.80]:
					var center: Vector2 = charge.direction * length * fraction
					var side: Vector2 = charge.direction.orthogonal() * 7.0
					var back: Vector2 = charge.direction * -10.0
					draw_line(center + side, center + back, Color("f4cf88", 0.86), 2.0)
					draw_line(center - side, center + back, Color("f4cf88", 0.86), 2.0)
				for offset: float in [-14.0, -5.0, 6.0, 15.0]:
					var streak_start: Vector2 = charge.direction * 30.0 + charge.direction.orthogonal() * offset
					draw_line(streak_start, streak_start + charge.direction * 26.0, Color("dff8ff", 0.52), 2.0)
			else:
				draw_line(end + perpendicular, end, Color("ffdc9f"), 3)
				draw_line(end - perpendicular, end, Color("ffdc9f"), 3)
		elif charge.state == ChargeBehavior.State.CHARGE and charge.crash_on_world_collision:
			for offset: float in [-15.0, -5.0, 5.0, 15.0]:
				var trail: Vector2 = -charge.direction * 20.0 + charge.direction.orthogonal() * offset
				draw_line(trail, trail - charge.direction * 34.0, Color("dff8ff", 0.58), 2.5)
		elif charge.state == ChargeBehavior.State.RECOVER:
			draw_arc(Vector2(0, -44), 10, _time * 4, _time * 4 + 4, 16, Color("ffd49c"), 2)
		return
	var skua := _enemy.behavior as SkuaSlingerBehavior
	if skua != null:
		# Perched-artillery language: small bird silhouette, amber arc dots, and
		# a red-orange landing ring. The ring is skua.locked_target itself.
		draw_arc(Vector2(0, -23), 18, PI, TAU, 20, Color("89c5ed"), 9)
		draw_circle(Vector2(0, -45), 6, Color("effbff"))
		if skua.state == RangedBehavior.State.WINDUP:
			var start := Vector2(18, -18)
			var target := to_local(skua.locked_target)
			var control := (start + target) * 0.5 + Vector2(0, -clampf(start.distance_to(target) * 0.22, 30.0, 76.0))
			for index: int in range(1, 9):
				var t: float = float(index) / 9.0
				var inv: float = 1.0 - t
				var point: Vector2 = start * inv * inv + control * 2.0 * inv * t + target * t * t
				draw_circle(point, 3.0, Color("f4cf88", 0.86))
			draw_arc(target, skua.landing_radius, 0.0, TAU, 32, Color("ff7d5c", 0.78), 2.5)
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