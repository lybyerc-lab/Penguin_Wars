extends CanvasLayer

var party: PartyRoster
var encounter: EncounterDirector
var progression: RunProgression
var builder: CastleBuilder
## Where the party is. The HUD is shared by the arena slice and the town.
var location: String = "Frostfall Bay"
var _title: Label
var _status: Label
var _readouts: Dictionary = {}
var _titles: Dictionary = {}
var _buttons: Dictionary = {}
var _build_buttons: Dictionary = {}
var _ready_buttons: Dictionary = {}
var _build_notes: Dictionary = {}
var _sheet: BuildSheet

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
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 22)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
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
	footer.offset_top = -45
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.text = "P1 WASD · SPACE dash · Q/E/T upgrades · B build · F ready   /   P2 ARROWS · CTRL dash · ENTER/SHIFT/PERIOD upgrades · N build · / ready\nPAD stick · X dash · A/B/RB upgrades · Y build · START ready   /   R restart   /   Break snowmen for health · Collect snowflakes for XP and shopping"
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
	for index: int in range(3):
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 13)
		button.text = RunProgression.OPTIONS[index].display_name
		button.pressed.connect(func() -> void: progression.choose(id, index))
		choices.add_child(button)
		_buttons[id].append(button)
	var actions := HBoxContainer.new()
	content.add_child(actions)
	var build_button := Button.new()
	build_button.focus_mode = Control.FOCUS_NONE
	build_button.add_theme_font_size_override("font_size", 13)
	build_button.text = "Build castle · 10"
	build_button.pressed.connect(func() -> void: builder.build(id))
	actions.add_child(build_button)
	_build_buttons[id] = build_button
	var ready_button := Button.new()
	ready_button.focus_mode = Control.FOCUS_NONE
	ready_button.add_theme_font_size_override("font_size", 13)
	ready_button.pressed.connect(func() -> void: progression.toggle_ready(id))
	actions.add_child(ready_button)
	_ready_buttons[id] = ready_button
	var note := Label.new()
	note.add_theme_font_size_override("font_size", 11)
	actions.add_child(note)
	_build_notes[id] = note
	var sheet_button := Button.new()
	sheet_button.text = "Stats / more upgrades"
	sheet_button.focus_mode = Control.FOCUS_NONE
	sheet_button.pressed.connect(func() -> void:
		if is_instance_valid(_sheet):
			return
		_sheet = BuildSheet.new()
		_sheet.player = player
		_sheet.progression = progression
		add_child(_sheet)
		_sheet.setup())
	content.add_child(sheet_button)

func _process(_delta: float) -> void:
	if _status == null:
		return
	_title.text = "PENGUIN WARS  /  %s" % location.to_upper()
	if encounter.definition == null or encounter.state == EncounterDirector.State.READY:
		_status.text = "EXPLORING · Reserve %d" % progression.reserve
	else:
		var phase: String = "SHOP / READY UP" if encounter.state == EncounterDirector.State.INTERMISSION else EncounterDirector.State.keys()[encounter.state]
		_status.text = "WAVE %d/%d · %s · Reserve %d" % [encounter.wave, encounter.definition.wave_count, phase, progression.reserve]
	for player: PenguinPlayer in party.members():
		var id: int = player.identity.player_id
		var choices: int = progression.pending.get(id, 0)
		var dash_status: String = "READY" if player.dash.cooldown_remaining <= 0 else "%.1fs" % player.dash.cooldown_remaining
		_titles[id].text = "P%d  /  %s    •    %s" % [id, player.weapon.definition.display_name.to_upper(), "%d HP" % player.health.current if player.health.is_alive() else "DOWN"]
		_readouts[id].text = "LV %d · XP %d/%d · Dash %s · Harvest x%.2f · Flakes %d · Free %d" % [player.experience.level, player.experience.xp, player.experience.required_xp(), dash_status, player.stats.harvest_multiplier, progression.wallet.balance(id), choices]
		for index: int in range(_buttons[id].size()):
			var button: Button = _buttons[id][index]
			var cost: String = "FREE" if choices > 0 else "%d" % progression.price(id, index)
			button.text = "%s · %s" % [RunProgression.OPTIONS[index].display_name, cost]
			button.disabled = not progression.can_choose(id, index) or not player.health.is_alive()
		_build_buttons[id].text = "Castle built" if builder.has_castle(id) else "Build castle · 10"
		_build_buttons[id].disabled = builder.has_castle(id) or progression.wallet.balance(id) < CastleBuilder.COST or not player.health.is_alive() or encounter.state in [EncounterDirector.State.COMPLETE, EncounterDirector.State.FAILED]
		_ready_buttons[id].text = "Ready ✓" if progression.ready_players.get(id, false) else "Ready for next wave"
		_ready_buttons[id].disabled = encounter.state != EncounterDirector.State.INTERMISSION or not player.health.is_alive()
		_build_notes[id].text = builder.last_result.get(id, "")
