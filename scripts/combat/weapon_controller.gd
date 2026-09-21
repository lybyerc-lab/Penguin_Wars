class_name WeaponController
extends Node2D

@export var definition: WeaponDefinition
var damage_bonus: float = 0.0
var wielder: PenguinPlayer
var _remaining: float = 0.0
var _flash: float = 0.0
var _hit_position: Vector2
var _aim: float = 0.0

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
		_aim = global_position.angle_to_point(_hit_position)
		if definition.pattern == WeaponDefinition.Pattern.SINGLE:
			_hit(target)
		else:
			for candidate: Node in get_tree().get_nodes_in_group("enemies"):
				var enemy := candidate as ArenaEnemy
				if enemy == null or not enemy.health.is_alive():
					continue
				var offset: Vector2 = enemy.global_position - global_position
				if offset.length() <= definition.reach and absf(wrapf(offset.angle() - _aim, -PI, PI)) <= deg_to_rad(definition.arc_degrees * 0.5):
					_hit(enemy)
		_remaining = definition.cooldown
		_flash = 0.18

func _hit(enemy: ArenaEnemy) -> void:
	var push: Vector2 = global_position.direction_to(enemy.global_position) * definition.knockback
	enemy.health.take_damage(DamageEvent.new(definition.damage + damage_bonus, wielder.identity.player_id, push))

func _draw() -> void:
	if _flash > 0.0:
		var tint := Color(definition.tint, _flash / 0.18)
		if definition.pattern == WeaponDefinition.Pattern.ARC:
			var half: float = deg_to_rad(definition.arc_degrees * 0.5)
			draw_arc(Vector2.ZERO, definition.reach * (1.0 - _flash), _aim - half, _aim + half, 24, tint, 8)
		else:
			draw_line(Vector2.ZERO, to_local(_hit_position), tint, 4.0)
			draw_circle(to_local(_hit_position), 7, tint)
