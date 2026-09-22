class_name WeaponController
extends Node2D

@export var definition: WeaponDefinition
var wielder: PenguinPlayer
var _remaining: float = 0.0
var _flash: float = 0.0
var _hit_position: Vector2
var aim_angle: float = 0.0
## Stable personal-rack identity. It is presentation/timing data only; hit
## range and target selection remain centered on the wielder.
var rack_slot: int = 0
var _phase_remaining: float = 0.0
var _had_target: bool = false
var _has_fired: bool = false

func configure_rack_slot(slot: int) -> void:
	rack_slot = slot
	_phase_remaining = firing_phase_delay()

func firing_phase_delay() -> float:
	return definition.cooldown * 0.12 * float(rack_slot) if definition != null else 0.0

## A cosmetic origin for held art and attack effects. Inventory slots remain
## stable, including holes left by maturation, so weapon count stays legible.
func presentation_origin(angle: float, thrust: float = 0.0) -> Vector2:
	var lateral: float = (float(rack_slot) - 2.5) * 11.0
	var forward := Vector2.from_angle(angle) * (33.0 + thrust)
	var side := Vector2.from_angle(angle + PI * 0.5) * lateral
	return forward + side + Vector2(0, 2)

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
		_phase_remaining = maxf(0.0, _phase_remaining - delta)
		if _flash <= 0.0:
			aim_angle = global_position.angle_to_point(target.global_position)
		if not _had_target and _has_fired and _remaining <= 0.0:
			_phase_remaining = firing_phase_delay()
			_had_target = true
			if _phase_remaining > 0.0:
				return
		_had_target = true
		if _phase_remaining > 0.0:
			return
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
		_has_fired = true
	elif _flash <= 0.0:
		_had_target = false
		aim_angle = wielder.dash.facing.angle()

func _hit(enemy: Node2D) -> void:
	var push: Vector2 = global_position.direction_to(enemy.global_position) * definition.knockback
	var damage: float = wielder.stats.weapon_damage(definition.damage + wielder.stats.flat_weapon_damage, definition.damage_kind == WeaponDefinition.DamageKind.MELEE, randf())
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
			draw_arc(presentation_origin(aim_angle), maxf(20, definition.reach + wielder.stats.range_bonus) * (1.0 - _flash), aim_angle - half, aim_angle + half, 24, tint, 5)
		else:
			draw_line(presentation_origin(aim_angle), to_local(_hit_position), tint, 4.0)
			draw_circle(to_local(_hit_position), 7, tint)
