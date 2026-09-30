class_name TouchControls
extends Control
## Tracks one movement finger; other fingers can use the context action without
## releasing movement. In ordinary play the right action remains Dash.
signal action_pressed

var input_source: LocalPlayerInput
var player: PenguinPlayer
var enabled: bool = true
var safe_inset := Vector2.ZERO
## Empty means the ordinary Dash action. Township services temporarily replace
## the right action label without adding another permanent mobile button.
var context_action_label: String = ""
var _finger: int = -1
var _stick := Vector2.ZERO
const RADIUS: float = 78.0
const RING_TEXTURE: Texture2D = preload("res://assets/ui/touch_v2/touch_stick_ring.png")
const KNOB_TEXTURE: Texture2D = preload("res://assets/ui/touch_v2/touch_stick_knob.png")
const DASH_TEXTURE: Texture2D = preload("res://assets/ui/touch_v2/touch_dash_icon.png")

func stick_center() -> Vector2:
	return Vector2(145 + safe_inset.x, size.y - 130 - safe_inset.y)

func dash_center() -> Vector2:
	return Vector2(size.x - 145 - safe_inset.x, size.y - 130 - safe_inset.y)

func set_context_action(label: String) -> void:
	if context_action_label == label:
		return
	context_action_label = label
	queue_redraw()

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
				if context_action_label.is_empty():
					input_source.touch_dash_pending = true
				else:
					action_pressed.emit()
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
	var active: bool = _finger >= 0
	draw_texture_rect(RING_TEXTURE, Rect2(stick_center() - Vector2(52, 52), Vector2(104, 104)), false, Color(1, 1, 1, 0.55 if active else 0.22))
	for angle: float in [0.0, PI * 0.5, PI, PI * 1.5]:
		var direction := Vector2.from_angle(angle)
		draw_line(stick_center() + direction * 45, stick_center() + direction * 50, Color(1, 1, 1, 0.36), 1.5)
	var knob_center: Vector2 = stick_center() + _stick * 31.0
	draw_texture_rect(KNOB_TEXTURE, Rect2(knob_center - Vector2(21, 21), Vector2(42, 42)), false, Color(1, 1, 1, 0.62 if active else 0.42))
	var pressed: bool = input_source != null and input_source.touch_dash_pending
	draw_circle(dash_center(), 34, Color(0.059, 0.133, 0.2, 0.45 if pressed else 0.30))
	draw_arc(dash_center(), 34, 0, TAU, 48, Color(1, 1, 1, 0.35), 1.8)
	var cooling: bool = player != null and player.dash.cooldown_remaining > 0.0
	draw_texture_rect(DASH_TEXTURE, Rect2(dash_center() - Vector2(15, 15), Vector2(30, 30)), false, Color(1, 1, 1, 0.45 if cooling else 0.85))
	if player != null and player.dash.cooldown > 0.0 and cooling:
		var ready: float = 1.0 - player.dash.cooldown_remaining / player.dash.cooldown
		draw_arc(dash_center(), 35.5, -PI * 0.5, -PI * 0.5 + TAU * ready, 40, Color("8fe6f2"), 3.0)
	if not context_action_label.is_empty():
		var pill := Rect2(dash_center() + Vector2(-48, -58), Vector2(96, 24))
		draw_style_box(_pill_style(), pill)
		draw_string(ThemeDB.fallback_font, pill.position + Vector2(0, 17), context_action_label, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x, 12, Color("ffc766"))

func _pill_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0f2233", 0.82)
	style.border_color = Color("ffc766", 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	return style
