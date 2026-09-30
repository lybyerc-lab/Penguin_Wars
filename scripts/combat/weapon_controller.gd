class_name WeaponController
extends Node2D

@export var definition: WeaponDefinition
var wielder: PenguinPlayer
var _remaining: float = 0.0
var _flash: float = 0.0
var _flash_duration: float = 0.18
var _hit_position: Vector2
var aim_angle: float = 0.0
## Stable personal-rack identity. It is presentation/timing data only; hit
## range and target selection remain centered on the wielder.
var rack_slot: int = 0
var _phase_remaining: float = 0.0
var _had_target: bool = false
var _has_fired: bool = false
## AREA weapons keep only a locked landing point + timer. The actual victims are
## resolved at impact, so moving out of a Snowbomb landing ring matters.
var _pending_area: bool = false
var _pending_area_position := Vector2.ZERO
var _pending_area_remaining: float = 0.0
var _pending_area_duration: float = 0.0

func configure_rack_slot(slot: int) -> void:
	rack_slot = slot
	_phase_remaining = firing_phase_delay()

func firing_phase_delay() -> float:
	return definition.cooldown * 0.12 * float(rack_slot) if definition != null else 0.0

## A cosmetic flipper origin for held art and attack effects. Slot identity and
## firing phase remain stable; only occupied weapons are centred in the fan.
func presentation_origin(angle: float, thrust: float = 0.0) -> Vector2:
	var lift: float = 0.0
	var visual := wielder.get_node_or_null("CharacterVisual") as CharacterVisual if wielder != null else null
	if visual != null:
		lift = visual.presentation_lift()
	return Vector2(0.0, -17.0) + Vector2(cos(angle) * 15.0, sin(angle) * 11.0 - lift * 1.5) + Vector2.from_angle(angle) * thrust

func _occupied_lane() -> Vector2i:
	if wielder == null or wielder.weapon_rack == null:
		return Vector2i(0, 1)
	var occupied_index: int = 0
	var occupied_count: int = 0
	for slot: int in range(wielder.weapon_rack.capacity()):
		if wielder.weapon_rack.weapon_at(slot) == null:
			continue
		if slot == rack_slot:
			occupied_index = occupied_count
		occupied_count += 1
	return Vector2i(occupied_index, maxi(1, occupied_count))

func _hold_distance() -> float:
	if definition == null:
		return 8.0
	match definition.id:
		&"icicle_slingshot":
			return 9.0
		_:
			return 8.0

func _physics_process(delta: float) -> void:
	_remaining = maxf(0.0, _remaining - delta)
	_flash = maxf(0.0, _flash - delta)
	queue_redraw()
	if wielder == null or definition == null or not wielder.health.is_alive():
		return

	if _pending_area:
		_pending_area_remaining = maxf(0.0, _pending_area_remaining - delta)
		_flash = _pending_area_remaining
		if _pending_area_remaining <= 0.0:
			_pending_area = false
			_hit_position = _pending_area_position
			_hit_area(_pending_area_position)
			_flash = 0.18
			_flash_duration = 0.18
		return

	var target: Node2D
	var reach: float = maxf(20, definition.reach + wielder.stats.range_bonus)
	var best: float = INF
	var targets: Array[Node] = _targets()
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
		if _phase_remaining > 0.0 or _remaining > 0.0:
			return

		_hit_position = target.global_position
		match definition.pattern:
			WeaponDefinition.Pattern.SINGLE:
				_hit(target)
			WeaponDefinition.Pattern.ARC:
				_hit_arc(targets, reach)
			WeaponDefinition.Pattern.LINE:
				_hit_line(targets, reach)
			WeaponDefinition.Pattern.AREA:
				_remaining = wielder.stats.cooldown(definition.cooldown)
				_has_fired = true
				if definition.travel_time > 0.0:
					_pending_area = true
					_pending_area_position = target.global_position
					_pending_area_remaining = definition.travel_time
					_pending_area_duration = definition.travel_time
					_flash = definition.travel_time
					_flash_duration = definition.travel_time
					return
				_hit_area(target.global_position)

		_remaining = wielder.stats.cooldown(definition.cooldown)
		_flash = 0.18
		_flash_duration = 0.18
		_has_fired = true
	elif _flash <= 0.0:
		_had_target = false
		aim_angle = wielder.dash.facing.angle()

func _targets() -> Array[Node]:
	return get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("breakables")

func _hit_arc(targets: Array[Node], reach: float) -> void:
	for candidate: Node in targets:
		var enemy := candidate as Node2D
		var health: Health = candidate.get_node_or_null("Health") as Health
		if enemy == null or health == null or not health.is_alive():
			continue
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length() <= reach and absf(wrapf(offset.angle() - aim_angle, -PI, PI)) <= deg_to_rad(definition.arc_degrees * 0.5):
			_hit(enemy)

func _hit_line(targets: Array[Node], reach: float) -> void:
	var direction := Vector2.from_angle(aim_angle)
	for candidate: Node in targets:
		var enemy := candidate as Node2D
		var health: Health = candidate.get_node_or_null("Health") as Health
		if enemy == null or health == null or not health.is_alive():
			continue
		var offset: Vector2 = enemy.global_position - global_position
		var forward: float = offset.dot(direction)
		var sideways: float = absf(offset.cross(direction))
		if forward >= 0.0 and forward <= reach and sideways <= definition.line_width:
			_hit(enemy)

func _hit_area(position: Vector2) -> void:
	for candidate: Node in _targets():
		var enemy := candidate as Node2D
		var health: Health = candidate.get_node_or_null("Health") as Health
		if enemy == null or health == null or not health.is_alive():
			continue
		if enemy.global_position.distance_to(position) <= definition.area_radius:
			_hit_from(enemy, position)

func _hit(enemy: Node2D) -> void:
	_hit_from(enemy, global_position)

func _hit_from(enemy: Node2D, impulse_origin: Vector2) -> void:
	var push: Vector2 = impulse_origin.direction_to(enemy.global_position) * definition.knockback
	var damage: float = wielder.stats.weapon_damage(definition.damage + wielder.stats.flat_weapon_damage, definition.damage_kind == WeaponDefinition.DamageKind.MELEE, randf())
	(enemy.get_node("Health") as Health).take_damage(DamageEvent.new(damage, wielder.identity.player_id, push))

func is_attacking() -> bool:
	return _flash > 0.0 or _pending_area

func has_target() -> bool:
	return _had_target

func is_projectile_in_flight() -> bool:
	return _pending_area

func projectile_target_position() -> Vector2:
	return _pending_area_position

func attack_progress() -> float:
	if _pending_area and _pending_area_duration > 0.0:
		return clampf(1.0 - _pending_area_remaining / _pending_area_duration, 0.0, 1.0)
	return clampf(1.0 - _flash / maxf(0.001, _flash_duration), 0.0, 1.0)

func _draw() -> void:
	if definition == null or wielder == null:
		return
	if _pending_area:
		var origin := presentation_origin(aim_angle)
		var target := to_local(_pending_area_position)
		var midpoint := (origin + target) * 0.5 + Vector2(0, -clampf(origin.distance_to(target) * 0.22, 28.0, 72.0))
		for index: int in range(1, 9):
			var t: float = float(index) / 9.0
			var inv: float = 1.0 - t
			var point: Vector2 = origin * inv * inv + midpoint * 2.0 * inv * t + target * t * t
			draw_circle(point, 3.5, Color("dff8ff", 0.60))
		draw_arc(target, definition.area_radius, 0.0, TAU, 36, Color("8fe6f2", 0.40), 2.5)
		return
	if _flash <= 0.0:
		return

	var alpha: float = clampf(_flash / maxf(0.001, _flash_duration), 0.0, 1.0)
	var tint := Color(definition.tint, alpha)
	match definition.pattern:
		WeaponDefinition.Pattern.ARC:
			var half: float = deg_to_rad(definition.arc_degrees * 0.5)
			draw_arc(presentation_origin(aim_angle), maxf(20, definition.reach + wielder.stats.range_bonus) * (1.0 - alpha), aim_angle - half, aim_angle + half, 24, tint, 5)
		WeaponDefinition.Pattern.AREA:
			var impact := to_local(_hit_position)
			draw_arc(impact, definition.area_radius * (1.05 - alpha * 0.25), 0.0, TAU, 36, tint, 4)
			draw_circle(impact, 8.0 + (1.0 - alpha) * 8.0, Color(definition.tint, alpha * 0.55))
		_:
			draw_line(presentation_origin(aim_angle), to_local(_hit_position), tint, 4.0)
			draw_circle(to_local(_hit_position), 7, tint)
