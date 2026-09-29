class_name WeaponVisual
extends Node2D
## Visible held art follows weapon aim; animation never drives damage timing.
const AMBIENT_TINT := Color(0.88, 0.91, 0.96)
var _weapon: WeaponController
var _sprite: Sprite2D

func _ready() -> void:
	_weapon = get_parent() as WeaponController
	_sprite = Sprite2D.new()
	add_child(_sprite)

func _process(_delta: float) -> void:
	if _weapon.definition == null or _weapon.wielder == null:
		return
	visible = _weapon.wielder.health.is_alive()
	var pattern: WeaponDefinition.Pattern = _weapon.definition.pattern
	_sprite.texture = _weapon.definition.held_texture
	_sprite.scale = Vector2.ONE * _weapon.definition.visual_scale
	_sprite.modulate = AMBIENT_TINT
	_sprite.visible = not (pattern == WeaponDefinition.Pattern.AREA and _weapon.is_projectile_in_flight())
	var progress: float = _weapon.attack_progress()
	var active: bool = _weapon.is_attacking()
	var angle: float = _weapon.aim_angle
	var thrust: float = 0.0
	if active:
		match pattern:
			WeaponDefinition.Pattern.ARC:
				angle += lerpf(-1.1, 1.1, progress)
			WeaponDefinition.Pattern.LINE:
				thrust = sin(progress * PI) * 17.0
			WeaponDefinition.Pattern.SINGLE:
				thrust = sin(progress * PI) * 10.0
			WeaponDefinition.Pattern.AREA:
				thrust = sin(progress * PI) * 7.0
	position = _weapon.presentation_origin(angle, thrust)
	rotation = angle
	_sprite.flip_v = cos(angle) < 0.0
	var grip_offset: Vector2 = _grip_offset()
	if _sprite.flip_v:
		grip_offset.y = -grip_offset.y
	_sprite.offset = grip_offset
	_sprite.rotation = PI * 0.5 if _weapon.definition.id == &"icicle_slingshot" else 0.0

func _grip_offset() -> Vector2:
	match _weapon.definition.id:
		&"fish_spear":
			return Vector2(24.0, 0.0)
		&"icicle_slingshot":
			return Vector2(0.0, -22.0)
		&"snowbomb":
			return Vector2(26.0, -3.0)
		_:
			return Vector2.ZERO
