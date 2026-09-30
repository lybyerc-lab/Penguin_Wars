class_name WeaponVisual
extends Node2D
## Presentation-only hand arbitration. Damage and timing remain controller-owned.

const AMBIENT_TINT := Color(0.88, 0.91, 0.96)
const BODY_CENTRE := Vector2(0, -17)
const HAND_RX: float = 15.0
const HAND_RY: float = 11.0
const BACK_HAND_OFFSET: float = 0.42
const FRONT_MIN_SIN: float = -0.40
const STOW_SCALE: float = 0.80
const SLING_SCALE: float = 0.75
const LINGER: float = 0.30
const SOCKETS := {
	&"spine": [Vector3(-6, -15, -125), Vector3(-10, -14, -140), Vector3(-2, -16, -110)],
	&"hip": [Vector3(-15, -15, 150), Vector3(-12, -12, 165), Vector3(-17, -18, 135)],
	&"sling": [Vector3(-15, -13, 0), Vector3(-19, -18, 0), Vector3(-11, -9, 0)],
}

var _weapon: WeaponController
var _back: Sprite2D
var _front: Sprite2D
var _was_attacking: bool = false
var _linger: float = 0.0
var _return_pop: float = 0.0

func _ready() -> void:
	_weapon = get_parent() as WeaponController
	_back = Sprite2D.new()
	_back.name = "Back"
	add_child(_back)
	_front = Sprite2D.new()
	_front.name = "WeaponFrontSlot%d" % _weapon.rack_slot
	_weapon.wielder.get_node("WeaponFront").add_child(_front)

func _exit_tree() -> void:
	if _weapon != null and _weapon.wielder != null and _weapon.wielder.weapon_rack != null:
		_weapon.wielder.weapon_rack.release_hand(_weapon.rack_slot)
	if is_instance_valid(_front): _front.queue_free()

func _process(delta: float) -> void:
	if _weapon.definition == null or _weapon.wielder == null: return
	var rack: WeaponRack = _weapon.wielder.weapon_rack
	var attacking: bool = _weapon.is_attacking()
	if attacking and not _was_attacking:
		rack.request_hand(_weapon.rack_slot)
	if attacking:
		_linger = LINGER
	elif _weapon.definition.pattern == WeaponDefinition.Pattern.SINGLE and _weapon.has_target():
		_linger = LINGER
	else:
		_linger = maxf(0.0, _linger - delta)
		if _linger <= 0.0: rack.release_hand(_weapon.rack_slot)
	if _was_attacking and not attacking and _weapon.definition.pattern == WeaponDefinition.Pattern.AREA:
		_return_pop = 0.12
	_return_pop = maxf(0.0, _return_pop - delta)
	_was_attacking = attacking
	var hand: StringName = rack.hand_of(_weapon.rack_slot)
	_apply_pose(hand, attacking)

func _apply_pose(hand: StringName, attacking: bool) -> void:
	var definition: WeaponDefinition = _weapon.definition
	var visual := _weapon.wielder.get_node("CharacterVisual") as CharacterVisual
	var facing: float = visual.facing_direction()
	var lift: float = visual.presentation_lift()
	var sway: float = visual.presentation_sway_x()
	var family: StringName = _family()
	var angle: float
	var target_position: Vector2
	var scale_factor: float = definition.visual_scale
	if hand == &"":
		var socket: Vector3 = SOCKETS[family][_duplicate_index()]
		target_position = Vector2(socket.x * facing, socket.y - lift)
		angle = deg_to_rad(socket.z)
		if facing < 0.0 and family != &"sling": angle = PI - angle
		scale_factor *= STOW_SCALE * (SLING_SCALE if family == &"sling" else 1.0)
		if attacking:
			angle += 0.18 * sin(PI * minf(_weapon.attack_progress() / 0.12, 1.0))
			target_position += Vector2.from_angle(angle) * 2.0
	else:
		angle = _weapon.aim_angle
		if hand == &"back": angle += BACK_HAND_OFFSET * (-1.0 if cos(angle) >= 0.0 else 1.0)
		target_position = BODY_CENTRE + Vector2(cos(angle) * HAND_RX + sway * 0.6 * facing, sin(angle) * HAND_RY - lift * 1.5)
		if attacking:
			var p: float = _weapon.attack_progress()
			match definition.pattern:
				WeaponDefinition.Pattern.LINE:
					var thrust: float = -4.0 * p / 0.15 if p < 0.15 else 14.0 * sin(PI * (p - 0.15) / 0.85)
					target_position += Vector2.from_angle(_weapon.aim_angle) * thrust
				WeaponDefinition.Pattern.SINGLE:
					var kick: float = sin(PI * minf(p / 0.30, 1.0))
					target_position -= Vector2.from_angle(_weapon.aim_angle) * 5.0 * kick
					angle -= 0.22 * kick * signf(cos(_weapon.aim_angle))
				WeaponDefinition.Pattern.ARC: angle += lerpf(-1.1, 1.1, p)
	if _return_pop > 0.0: scale_factor *= lerpf(0.6, 1.0, 1.0 - _return_pop / 0.12)
	var use_front: bool = hand == &"front" and sin(_weapon.aim_angle) >= FRONT_MIN_SIN
	var sprite: Sprite2D = _front if use_front else _back
	_back.visible = sprite == _back
	_front.visible = sprite == _front
	var hidden: bool = definition.pattern == WeaponDefinition.Pattern.AREA and _weapon.is_projectile_in_flight()
	sprite.visible = sprite.visible and not hidden and _weapon.wielder.health.is_alive()
	sprite.texture = definition.held_texture
	sprite.position = target_position
	sprite.rotation = angle + definition.held_base_rotation
	sprite.scale = Vector2.ONE * scale_factor
	sprite.modulate = Color(1.15, 1.15, 1.15) if attacking and hand == &"" else AMBIENT_TINT
	sprite.flip_v = family == &"spine" and cos(angle) < 0.0
	sprite.offset = _grip_offset(definition)

func _family() -> StringName:
	if _weapon.definition.presentation_family != &"": return _weapon.definition.presentation_family
	match _weapon.definition.pattern:
		WeaponDefinition.Pattern.SINGLE: return &"hip"
		WeaponDefinition.Pattern.AREA: return &"sling"
		_: return &"spine"

func _duplicate_index() -> int:
	var count: int = 0
	for slot: int in range(_weapon.rack_slot):
		var prior: WeaponDefinition = _weapon.wielder.weapon_rack.weapon_at(slot)
		if prior != null and prior.family_id == _weapon.definition.family_id: count += 1
	return count % 3

func _grip_offset(definition: WeaponDefinition) -> Vector2:
	if definition.held_texture == null: return Vector2.ZERO
	if definition.held_grip_texel.x >= 0.0:
		return Vector2(definition.held_texture.get_width(), definition.held_texture.get_height()) * 0.5 - definition.held_grip_texel
	return Vector2.ZERO
