class_name TouchControls
extends Control
## Tracks one movement finger; other fingers can dash without releasing movement.
var input_source: LocalPlayerInput
var player: PenguinPlayer
var enabled: bool = true
var safe_inset := Vector2.ZERO
var _finger: int = -1
var _stick := Vector2.ZERO
const RADIUS: float = 78.0

func stick_center() -> Vector2:
	return Vector2(145 + safe_inset.x, size.y - 130 - safe_inset.y)

func dash_center() -> Vector2:
	return Vector2(size.x - 145 - safe_inset.x, size.y - 130 - safe_inset.y)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(reset_input)

func _input(event: InputEvent) -> void:
	if not enabled or input_source == null:
		return
	if event is InputEventScreenTouch:
		if event.index == _finger and (not event.pressed or event.canceled):
			reset_input()
		elif event.pressed and not event.canceled:
			if _finger == -1 and event.position.distance_to(stick_center()) <= RADIUS * 1.6:
				_finger = event.index
				_move(event.position)
				get_viewport().set_input_as_handled()
			elif event.position.distance_to(dash_center()) <= 66:
				input_source.touch_dash_pending = true
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _finger:
		_move(event.position)
		get_viewport().set_input_as_handled()

func _move(point: Vector2) -> void:
	_stick = ((point - stick_center()) / RADIUS).limit_length()
	input_source.touch_movement = Vector2.ZERO if _stick.length() < 0.12 else _stick
	queue_redraw()

func reset_input() -> void:
	_finger = -1
	_stick = Vector2.ZERO
	if input_source != null:
		input_source.touch_movement = Vector2.ZERO
		input_source.touch_dash_pending = false
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		reset_input()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not enabled:
		return
	draw_circle(stick_center(), RADIUS, Color(0.02, 0.09, 0.16, 0.7))
	draw_arc(stick_center(), RADIUS, 0, TAU, 48, Color("8cd7df"), 3)
	draw_circle(stick_center() + _stick * 46, 30, Color("b8eeee"))
	draw_circle(dash_center(), 66, Color(0.02, 0.09, 0.16, 0.8))
	draw_arc(dash_center(), 66, 0, TAU, 48, Color("ffcb77"), 3)
	var text: String = "DASH" if player == null or player.dash.cooldown_remaining <= 0 else "%.1fs" % player.dash.cooldown_remaining
	draw_string(ThemeDB.fallback_font, dash_center() + Vector2(-30, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
