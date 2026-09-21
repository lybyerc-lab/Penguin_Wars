extends CanvasLayer

var party: PartyRoster
var encounter: EncounterDirector
var progression: RunProgression
var _status: Label
var _players: VBoxContainer
var _readouts: Dictionary = {}

func setup() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	var title := Label.new()
	title.text = "PENGUIN WARS  /  ICE FIELD"
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)
	_status = Label.new()
	column.add_child(_status)
	_players = VBoxContainer.new()
	column.add_child(_players)
	for player: PenguinPlayer in party.members():
		var row := HBoxContainer.new()
		_players.add_child(row)
		var label := Label.new()
		label.custom_minimum_size.x = 410
		label.modulate = player.identity.tint
		row.add_child(label)
		_readouts[player.identity.player_id] = label
		for index: int in range(RunProgression.OPTIONS.size()):
			var button := Button.new()
			button.focus_mode = Control.FOCUS_NONE
			button.text = RunProgression.OPTIONS[index].display_name
			button.pressed.connect(func() -> void: progression.choose(player.identity.player_id, index))
			row.add_child(button)
	var help := Label.new()
	help.text = "P1  WASD + Q/E upgrades    •    P2  Arrows + Enter/Shift upgrades    •    Auto attack    •    R restart\nGamepads: left stick + A/B upgrades. Upgrade buttons also support mouse."
	help.add_theme_color_override("font_color", Color("8ba6bd"))
	column.add_child(help)

func _process(_delta: float) -> void:
	if _status == null:
		return
	_status.text = "Wave %d / %d   •   %s   •   Enemies %d" % [encounter.wave, encounter.definition.wave_count, EncounterDirector.State.keys()[encounter.state], encounter.alive_count]
	for player: PenguinPlayer in party.members():
		var id: int = player.identity.player_id
		_readouts[id].text = "P%d  %s   LV %d   XP %d/%d   Choices %d" % [id, str(int(player.health.current)) + " HP" if player.health.is_alive() else "DOWN", player.experience.level, player.experience.xp, player.experience.required_xp(), progression.pending.get(id, 0)]
		var row: Node = _readouts[id].get_parent()
		for child: Node in row.get_children():
			if child is Button:
				child.disabled = progression.pending.get(id, 0) == 0 or not player.health.is_alive()
