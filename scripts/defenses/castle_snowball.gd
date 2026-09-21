class_name CastleSnowball
extends Node2D
var direction := Vector2.RIGHT
var damage: float = 8.0
var source_player_id: int = 1
var _remaining: float = 1.5
var _spent: bool = false

func _physics_process(delta: float) -> void:
	if _spent:
		return
	var start: Vector2 = global_position
	var finish: Vector2 = start + direction * 330.0 * delta
	var query := PhysicsRayQueryParameters2D.create(start, finish, 1)
	var wall: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty():
		finish = wall.position
	var target: ArenaEnemy
	var best: float = INF
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as ArenaEnemy
		if enemy == null or not enemy.health.is_alive():
			continue
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(enemy.global_position, start, finish)
		if closest.distance_squared_to(enemy.global_position) <= 21.0 * 21.0 and start.distance_squared_to(closest) < best:
			best = start.distance_squared_to(closest)
			target = enemy
	global_position = finish
	if target != null:
		target.health.take_damage(DamageEvent.new(damage, source_player_id, direction * 45))
	_remaining -= delta
	if target != null or not wall.is_empty() or _remaining <= 0.0:
		_expire()

func _expire() -> void:
	_spent = true
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 7, Color("216a70"))
	draw_circle(Vector2.ZERO, 5, Color("8fffd0"))
	draw_circle(Vector2(-1, -1), 3, Color("f0fff2"))
