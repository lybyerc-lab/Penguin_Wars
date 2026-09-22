class_name CaveTravelHUD
extends CanvasLayer
## Shared party exit choices. The character sheets render above this layer.
var journey: CaveJourney
var _panel: PanelContainer
var _title: Label
var _description: Label
var _next: Button
var _town: Button

func setup() -> void:
	layer = 0
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.offset_left = -330
	_panel.offset_right = 330
	_panel.offset_top = -120
	_panel.offset_bottom = 120
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.12, 0.17, 0.96)
	style.border_color = Color("b6ece9")
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(24)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	_panel.add_child(content)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 32)
	content.add_child(_title)
	_description = Label.new()
	_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description.add_theme_font_size_override("font_size", 18)
	content.add_child(_description)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	content.add_child(actions)
	_next = _button("Next cave", _next_pressed, actions)
	_town = _button("Back to town", _town_pressed, actions)
	_panel.hide()
	journey.cave_cleared.connect(_on_cleared)
	journey.location_changed.connect(_on_location_changed)

func _button(text: String, callback: Callable, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(285, 64)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _on_cleared(number: int) -> void:
	_title.text = "CAVE CLEARED!"
	_description.text = "Cave %d complete · Rewards collected\nChoose the party's next destination, or open your stats to shop." % number
	_next.text = "Next cave · %d" % (number + 1)
	_town.show()
	_town.text = "Back to town"
	if journey.war_choice_pending():
		_title.text = "MONDO DEFEATED!"
		_description.text = "Twenty caves. One war king. Your choice.\nBring peace to town, or keep your build and brave endless caves."
		_next.text = "Endless caves"
		_town.text = "End the war"
	_panel.show()

func _next_pressed() -> void:
	if journey.war_ended:
		get_tree().reload_current_scene()
	elif journey.war_choice_pending():
		journey.choose_endless()
	else:
		journey.next_cave()

func _town_pressed() -> void:
	if journey.war_choice_pending():
		journey.end_war()
	else:
		journey.return_to_town()

func _on_location_changed(town: bool, number: int) -> void:
	_panel.visible = town
	if town:
		_title.text = "EXPEDITION CAMP"
		_description.text = "Your build, health, levels and flakes are retained.\nOpen your penguin card to shop, then head back into the caves."
		_next.text = "Enter cave %d" % (number + 1)
		if journey.war_ended:
			_title.text = "THE WAR IS OVER!"
			_description.text = "Mondo has fallen. Frostfall Town is safe.\nYour expedition is complete. Enjoy the peace, penguins."
			_next.text = "Start a new expedition"
		_town.hide()
		_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		_panel.offset_left = -330
		_panel.offset_right = 330
		_panel.offset_top = -250
		_panel.offset_bottom = -24
	else:
		_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_panel.offset_left = -330
		_panel.offset_right = 330
		_panel.offset_top = -120
		_panel.offset_bottom = 120
	var banner := LocationBanner.new()
	banner.location_name = journey.location_title()
	add_child(banner)
