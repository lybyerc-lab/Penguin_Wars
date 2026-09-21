class_name EnemySnowball
extends Node2D
## Swept hit test avoids tunneling. Each shot can hit one living party member.
var party: PartyRoster
var direction := Vector2.RIGHT
var speed: float = 230.0
var damage: float = 10.0
var lifetime: float = 3.0
var spent: bool = false

func _ready() -> void:
	add_to_group("enemy_projectiles")
	z_index = 2

func _physics_process(delta: float) -> void:
	if spent:
		return
	if party == null or party.members(true).is_empty():
		_expire()
		return
	var start: Vector2 = global_position
	var finish: Vector2 = start + direction.normalized() * speed * delta
	# Stop at world walls too, when future rooms provide layer-1 collision.
	var query := PhysicsRayQueryParameters2D.create(start, finish, 1)
	var wall: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty():
		finish = wall.position
	var victim: PenguinPlayer
	var nearest: float = INF
	for player: PenguinPlayer in party.members(true):
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(player.global_position, start, finish)
		if closest.distance_squared_to(player.global_position) <= 23.0 * 23.0:
			var distance: float = start.distance_squared_to(closest)
			if distance < nearest:
				nearest = distance
				victim = player
	global_position = finish
	if victim != null:
		victim.health.take_damage(DamageEvent.new(damage))
		_expire()
		return
	lifetime -= delta
	var shot_bounds: Rect2 = party.members()[0].arena_bounds.grow(60)
	if not wall.is_empty() or lifetime <= 0.0 or not shot_bounds.has_point(global_position):
		_expire()
	queue_redraw()

func _expire() -> void:
	spent = true
	queue_free()

func _draw() -> void:
	draw_line(-direction * 19, Vector2.ZERO, Color(0.68, 0.9, 1, 0.5), 5)
	draw_circle(Vector2(1, 5), 9, Color(0.03, 0.12, 0.22, 0.3))
	draw_circle(Vector2.ZERO, 9, Color("274967"))
	draw_circle(Vector2.ZERO, 7, Color("c1ecff"))
	draw_circle(Vector2(-2, -2), 4, Color("ffffff"))
