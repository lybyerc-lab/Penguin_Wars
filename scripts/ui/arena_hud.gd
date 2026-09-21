extends CanvasLayer

var party: PartyRoster
var encounter: EncounterDirector
var progression: RunProgression
var _status: Label
var _readouts: Dictionary = {}
var _titles: Dictionary = {}
var _buttons: Dictionary = {}

func setup() -> void:
	var top := MarginContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.add_theme_constant_override("margin_left", 24)
	top.add_theme_constant_override("margin_right", 24)
	top.add_theme_constant_override("margin_top", 14)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "PENGUIN WARS  /  FROSTFALL BAY"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_status = Label.new()
	_status.add_theme_color_override("font_color", Color("bddfe5"))
	header.add_child(_status)
	var cards := GridContainer.new()
	cards.columns = 2
	cards.add_theme_constant_override("h_separation", 12)
	cards.add_theme_constant_override("v_separation", 8)
	column.add_child(cards)
	for player: PenguinPlayer in party.members():
		_add_card(cards, player)
	var footer := Label.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -36
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.text = "P1  WASD · SPACE dash · Q/E upgrades   /   P2  ARROWS · CTRL dash · ENTER/SHIFT upgrades   /   PAD  Left stick · X dash · A/B upgrades   /   R restart"
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color("c9e4e8"))
	add_child(footer)

func _add_card(parent: GridContainer, player: PenguinPlayer) -> void:
	var id: int = player.identity.player_id
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.10, 0.16, 0.94)
	style.border_color = player.identity.tint
	style.border_width_left = 4
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var content := VBoxContainer.new()
	panel.add_child(content)
	var title := Label.new()
	title.modulate = player.identity.tint
	content.add_child(title)
	_titles[id] = title
	var readout := Label.new()
	readout.add_theme_font_size_override("font_size", 14)
	readout.modulate = Color("b7cddc")
	content.add_child(readout)
	_readouts[id] = readout
	var choices := HBoxContainer.new()
	content.add_child(choices)
	_buttons[id] = []
	for index: int in range(RunProgression.OPTIONS.size()):
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 13)
		button.text = RunProgression.OPTIONS[index].display_name
		button.pressed.connect(func() -> void: progression.choose(id, index))
		choices.add_child(button)
		_buttons[id].append(button)

func _process(_delta: float) -> void:
	if _status == null:
		return
	_status.text = "WAVE %d / %d   •   %s   •   %d raiders" % [encounter.wave, encounter.definition.wave_count, EncounterDirector.State.keys()[encounter.state], encounter.alive_count]
	for player: PenguinPlayer in party.members():
		var id: int = player.identity.player_id
		var choices: int = progression.pending.get(id, 0)
		var dash_status: String = "READY" if player.dash.cooldown_remaining <= 0 else "%.1fs" % player.dash.cooldown_remaining
		_titles[id].text = "P%d  /  %s    •    %s" % [id, player.weapon.definition.display_name.to_upper(), "%d HP" % player.health.current if player.health.is_alive() else "DOWN"]
		_readouts[id].text = "Level %d   •   XP %d/%d   •   Dash %s   •   %d upgrades ready" % [player.experience.level, player.experience.xp, player.experience.required_xp(), dash_status, choices]
		for button: Button in _buttons[id]:
			button.disabled = choices == 0 or not player.health.is_alive()
