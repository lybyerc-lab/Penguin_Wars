class_name WeaponController
extends Node2D

@export var definition: WeaponDefinition
var damage_bonus: float = 0.0
var wielder: PenguinPlayer
var _remaining: float = 0.0
var _flash: float = 0.0
var _hit_position: Vector2
var aim_angle: float = 0.0

func _physics_process(delta: float) -> void:
	_remaining = maxf(0.0, _remaining - delta)
	_flash = maxf(0.0, _flash - delta)
	queue_redraw()
	if wielder == null or definition == null or not wielder.health.is_alive():
		return
	var target: Node2D
	var reach: float = maxf(20, definition.reach + wielder.stats.range_bonus)
	var best: float = INF
	var targets: Array[Node] = get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("breakables")
	for candidate: Node in targets:
		var enemy := candidate as Node2D
		var health: Health = candidate.get_node_or_null("Health") as Health
		if enemy == null or health == null or not health.is_alive():
			continue
		var distance: float = global_position.distance_squared_to(enemy.global_position)
		if distance >= reach * reach:
			continue
		# Threats always win targeting priority over supply props.
		var score: float = distance + (reach * reach if enemy.is_in_group("breakables") else 0.0)
		if score < best:
			best = score
			target = enemy
	if target != null:
		if _flash <= 0.0:
			aim_angle = global_position.angle_to_point(target.global_position)
		if _remaining > 0.0:
			return
		_hit_position = target.global_position
		if definition.pattern == WeaponDefinition.Pattern.SINGLE:
			_hit(target)
		else:
			for candidate: Node in targets:
				var enemy := candidate as Node2D
				var health: Health = candidate.get_node_or_null("Health") as Health
				if enemy == null or health == null or not health.is_alive():
					continue
				var offset: Vector2 = enemy.global_position - global_position
				if offset.length() <= reach and absf(wrapf(offset.angle() - aim_angle, -PI, PI)) <= deg_to_rad(definition.arc_degrees * 0.5):
					_hit(enemy)
		_remaining = wielder.stats.cooldown(definition.cooldown)
		_flash = 0.18
	elif _flash <= 0.0:
		aim_angle = wielder.dash.facing.angle()

func _hit(enemy: Node2D) -> void:
	var push: Vector2 = global_position.direction_to(enemy.global_position) * definition.knockback
	var damage: float = wielder.stats.weapon_damage(definition.damage + damage_bonus, definition.damage_kind == WeaponDefinition.DamageKind.MELEE, randf())
	(enemy.get_node("Health") as Health).take_damage(DamageEvent.new(damage, wielder.identity.player_id, push))

func is_attacking() -> bool:
	return _flash > 0.0

func attack_progress() -> float:
	return clampf(1.0 - _flash / 0.18, 0.0, 1.0)

func _draw() -> void:
	if _flash > 0.0:
		var tint := Color(definition.tint, _flash / 0.18)
		if definition.pattern == WeaponDefinition.Pattern.ARC:
			var half: float = deg_to_rad(definition.arc_degrees * 0.5)
			draw_arc(Vector2.ZERO, maxf(20, definition.reach + wielder.stats.range_bonus) * (1.0 - _flash), aim_angle - half, aim_angle + half, 24, tint, 5)
		else:
			draw_line(Vector2.ZERO, to_local(_hit_position), tint, 4.0)
			draw_circle(to_local(_hit_position), 7, tint)
