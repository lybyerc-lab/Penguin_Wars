class_name WeaponController
extends Node2D

@export var definition: WeaponDefinition
var damage_bonus: float = 0.0
var wielder: PenguinPlayer
var _remaining: float = 0.0
var _flash: float = 0.0
var _hit_position: Vector2

func _physics_process(delta: float) -> void:
	_remaining = maxf(0.0, _remaining - delta)
	_flash = maxf(0.0, _flash - delta)
	queue_redraw()
	if wielder == null or definition == null or not wielder.health.is_alive() or _remaining > 0.0:
		return
	var target: ArenaEnemy
	var best: float = definition.reach * definition.reach
	for candidate: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := candidate as ArenaEnemy
		if enemy == null or not enemy.health.is_alive():
			continue
		var distance: float = global_position.distance_squared_to(enemy.global_position)
		if distance < best:
			best = distance
			target = enemy
	if target != null:
		_hit_position = target.global_position
		target.health.take_damage(DamageEvent.new(definition.damage + damage_bonus, wielder.identity.player_id))
		_remaining = definition.cooldown
		_flash = 0.12

func _draw() -> void:
	if _flash > 0.0:
		draw_line(Vector2.ZERO, to_local(_hit_position), Color("baf9ff"), 3.0)
