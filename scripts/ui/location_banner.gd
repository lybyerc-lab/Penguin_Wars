class_name LocationBanner
extends Control
## Arrival-only overlay; ignores input and removes itself after fading away.
var location_name: String = "FROSTFALL BAY"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -280
	offset_right = 280
	offset_top = -54
	offset_bottom = 54
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
	label.text = location_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(label)
	modulate.a = 0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.35)
	tween.tween_interval(1.4)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)
