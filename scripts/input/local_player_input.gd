class_name LocalPlayerInput
extends Node
## Input adapter only; simulation consumes a normalized movement command.
var identity: PlayerIdentity

func movement() -> Vector2:
	if identity == null:
		return Vector2.ZERO
	var axis := Vector2.ZERO
	if identity.local_slot == 0:
		axis = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	elif identity.local_slot == 1:
		axis = Vector2(float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP)))
	if identity.device_id >= 0 and identity.device_id in Input.get_connected_joypads():
		var stick := Vector2(Input.get_joy_axis(identity.device_id, JOY_AXIS_LEFT_X), Input.get_joy_axis(identity.device_id, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.2:
			axis = stick * ((stick.length() - 0.2) / 0.8) / stick.length()
	return axis.limit_length()
