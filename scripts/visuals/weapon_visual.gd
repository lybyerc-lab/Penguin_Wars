class_name WeaponVisual
extends Node2D
## Visible held art follows weapon aim; animation never drives damage timing.
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
	var cleaver: bool = _weapon.definition.pattern == WeaponDefinition.Pattern.ARC
	_sprite.texture = _weapon.definition.held_texture
	_sprite.scale = Vector2.ONE * _weapon.definition.visual_scale
	var progress: float = _weapon.attack_progress()
	var active: bool = _weapon.is_attacking()
	var angle: float = _weapon.aim_angle
	var thrust: float = 0.0
	if active:
		if cleaver:
			angle += lerpf(-1.1, 1.1, progress)
		else:
			thrust = sin(progress * PI) * 17
	position = _weapon.presentation_origin(angle, thrust)
	rotation = angle
	_sprite.flip_v = cos(angle) < 0.0
