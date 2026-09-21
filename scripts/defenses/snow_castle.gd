class_name SnowCastle
extends Node2D
var player_id: int = 1
var party: PartyRoster
var tint := Color("8fffd0")
var _cooldown: float = 0.0
var _direction := Vector2.RIGHT
var _barrel: Line2D
var _barrel_fill: Line2D

func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = preload("res://assets/props/snow_castle.svg")
	sprite.scale = Vector2.ONE * 0.65
	sprite.position.y = -12
	add_child(sprite)
	_barrel = Line2D.new()
	_barrel.width = 12
	_barrel.default_color = Color("365970")
	add_child(_barrel)
	_barrel_fill = Line2D.new()
	_barrel_fill.width = 7
	_barrel_fill.default_color = Color("b4e9df")
	add_child(_barrel_fill)
	_update_barrel()

func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if party == null or party.members(true).is_empty():
		return
	var target: ArenaEnemy
	var best: float = 275.0 * 275.0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as ArenaEnemy
		if enemy != null and enemy.health.is_alive():
			var distance: float = global_position.distance_squared_to(enemy.global_position)
			if distance < best:
				best = distance
				target = enemy
	if target == null:
		return
	_direction = global_position.direction_to(target.global_position)
	_update_barrel()
	queue_redraw()
	if _cooldown > 0:
		return
	var snowball := CastleSnowball.new()
	snowball.position = position + _direction * 32
	snowball.direction = _direction
	snowball.source_player_id = player_id
	for player: PenguinPlayer in party.members():
		if player.identity.player_id == player_id:
			snowball.damage = maxf(1.0, 8.0 + player.stats.engineering)
	get_parent().add_child(snowball)
	_cooldown = 0.9

func _draw() -> void:
	draw_set_transform(Vector2(0, 18), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 35, Color(0.02, 0.12, 0.2, 0.25))
	draw_arc(Vector2.ZERO, 37, 0, TAU, 32, tint, 3)
	draw_set_transform(Vector2.ZERO)

func _update_barrel() -> void:
	var points := PackedVector2Array([Vector2(0, -10), Vector2(0, -10) + _direction * 38])
	_barrel.points = points
	_barrel_fill.points = points
