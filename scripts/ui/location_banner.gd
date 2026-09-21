class_name LocationBanner
extends Control
## Arrival-only overlay. Ignores input and removes itself once it has faded,
## so a room change leaves nothing behind.

## Sits in the gap between the player cards and the room, never over the play
## area: a room's fight can begin the moment the party arrives.
const TOP_OFFSET: float = 124.0
const WIDE_PARTY_TOP_OFFSET: float = 124.0

var location_name: String = "Frostfall Bay"
var wide_party: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	offset_left = -300
	offset_right = 300
	offset_top = WIDE_PARTY_TOP_OFFSET if wide_party else TOP_OFFSET
	offset_bottom = offset_top + 64.0
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.12, 0.18, 0.86)
	style.border_color = Color("b6ece9")
	style.border_width_top = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var label := Label.new()
	label.text = location_name.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(label)
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.7)
	tween.tween_callback(queue_free)
