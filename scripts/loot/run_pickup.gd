class_name RunPickup
extends Node2D
## Pickup owns collection eligibility; the run decides where currency is credited.
signal collected(player_id: int, amount: int)
enum Kind { HEALTH, SNOWFLAKE }
@export var kind: Kind = Kind.HEALTH
@export var amount: int = 25
var party: PartyRoster
var claimed: bool = false
var _age: float = 0.0

func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if party == null or claimed or _age < 0.3:
		return
	var nearest: PenguinPlayer
	var best: float = INF
	for player: PenguinPlayer in party.members(true):
		if kind == Kind.HEALTH and player.health.current >= player.health.maximum:
			continue
		var distance: float = global_position.distance_squared_to(player.global_position)
		var reach: float = maxf(30, 30 + player.stats.pickup_bonus)
		if distance <= reach * reach and distance < best:
			best = distance
			nearest = player
	if nearest != null:
		collect(nearest)

func collect(player: PenguinPlayer) -> bool:
	if claimed or amount <= 0 or not player.health.is_alive():
		return false
	if kind == Kind.HEALTH:
		if player.health.current >= player.health.maximum:
			return false
		player.health.heal(amount)
	claimed = true
	collected.emit(player.identity.player_id, amount)
	queue_free()
	return true

func _draw() -> void:
	var bob: float = sin(_age * 4) * 2
	draw_set_transform(Vector2(0, 7), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 12, Color(0, 0.1, 0.2, 0.2))
	draw_set_transform(Vector2(0, bob))
	if kind == Kind.HEALTH:
		draw_circle(Vector2.ZERO, 12, Color("275666"))
		draw_circle(Vector2.ZERO, 10, Color("81dda9"))
		draw_rect(Rect2(-2, -7, 4, 14), Color("effff1"))
		draw_rect(Rect2(-7, -2, 14, 4), Color("effff1"))
	else:
		draw_circle(Vector2.ZERO, 12, Color("284967"))
		for index: int in range(6):
			var direction := Vector2.from_angle(index * TAU / 6)
			var side: Vector2 = direction.orthogonal()
			draw_line(Vector2.ZERO, direction * 10, Color("baf6ff"), 2)
			draw_line(direction * 6, direction * 3 + side * 3, Color("baf6ff"), 2)
			draw_line(direction * 6, direction * 3 - side * 3, Color("baf6ff"), 2)
	draw_set_transform(Vector2.ZERO)
