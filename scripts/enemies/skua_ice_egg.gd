class_name SkuaIceEgg
extends Node2D
## Lobbed artillery shot. Movement is visual until the locked landing point is
## reached; damage happens only inside the telegraphed ring.

var party: PartyRoster
var damage: float = 10.0
var travel_time: float = 0.62
var landing_radius: float = 42.0
var landing_position := Vector2.ZERO
var room_bounds := Rect2(-540, -260, 1080, 520)
var spent: bool = false
var _elapsed: float = 0.0
var _start := Vector2.ZERO

func _ready() -> void:
	add_to_group("enemy_projectiles")
	z_index = 2
	_start = global_position
	queue_redraw()

func _physics_process(delta: float) -> void:
	if spent:
		return
	if party == null or party.members(true).is_empty():
		_expire()
		return
	_elapsed += delta
	var duration: float = maxf(0.05, travel_time)
	var t: float = clampf(_elapsed / duration, 0.0, 1.0)
	var flat: Vector2 = _start.lerp(landing_position, t)
	var height: float = minf(74.0, _start.distance_to(landing_position) * 0.24)
	global_position = flat + Vector2(0, -sin(t * PI) * height)
	if t >= 1.0:
		global_position = landing_position
		for player: PenguinPlayer in party.members(true):
			if player.global_position.distance_to(landing_position) <= landing_radius:
				player.health.take_damage(DamageEvent.new(damage))
		_expire()
		return
	if room_bounds.has_area() and not room_bounds.grow(80.0).has_point(flat):
		_expire()
		return
	queue_redraw()

func _expire() -> void:
	spent = true
	queue_free()

func _draw() -> void:
	var ring_local: Vector2 = to_local(landing_position)
	draw_arc(ring_local, landing_radius, 0.0, TAU, 32, Color("ff7d5c", 0.72), 2.5)
	draw_circle(Vector2(2, 5), 8, Color(0.03, 0.12, 0.22, 0.28))
	draw_circle(Vector2.ZERO, 8, Color("d9f5ff"))
	draw_circle(Vector2(-2, -2), 3, Color.WHITE)
