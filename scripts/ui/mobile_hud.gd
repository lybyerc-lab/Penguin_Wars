class_name MobileHUD
extends CanvasLayer
var party: PartyRoster
var encounter: EncounterDirector
var progression: RunProgression
var builder: CastleBuilder
var controls: TouchControls
var _player: PenguinPlayer
var _status: Label
var _build: Button
var _ready_button: Button
var _sheet: BuildSheet
var _root: Control
var _paused_for_sheet: bool = false

func setup() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = party.members()[0]
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	controls = TouchControls.new()
	controls.input_source = _player.input_source
	controls.player = _player
	_root.add_child(controls)
	var inset := Vector2(28, 16)
	if OS.has_feature("android"):
		var safe: Rect2i = DisplayServer.get_display_safe_area()
		var screen := Vector2(DisplayServer.window_get_size())
		if safe.size.x > 0 and screen.x > 0:
			var ratio: Vector2 = get_viewport().get_visible_rect().size / screen
			inset.x = maxf(inset.x, maxf(safe.position.x, screen.x - safe.end.x) * ratio.x + 16)
			inset.y = maxf(inset.y, maxf(safe.position.y, screen.y - safe.end.y) * ratio.y + 8)
	controls.safe_inset = inset
	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = inset.x
	top.offset_right = -inset.x
	top.offset_top = inset.y
	_root.add_child(top)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 26)
	_status.add_theme_color_override("font_shadow_color", Color("102c41"))
	_status.add_theme_constant_override("shadow_offset_x", 2)
	_status.add_theme_constant_override("shadow_offset_y", 2)
	top.add_child(_status)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	top.add_child(actions)
	_build = _button("Build castle · 10", func() -> void: builder.build(1), actions)
	_button("Character / Shop", open_sheet, actions)
	_ready_button = _button("Next wave", func() -> void: progression.toggle_ready(1), actions)
	_button("Restart", func() -> void: get_tree().reload_current_scene(), actions)
	encounter.state_changed.connect(_on_state_changed)

func _button(text: String, callback: Callable, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180, 68)
	button.add_theme_font_size_override("font_size", 22)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func open_sheet() -> void:
	if is_instance_valid(_sheet):
		return
	controls.enabled = false
	controls.reset_input()
	_paused_for_sheet = not get_tree().paused
	get_tree().paused = true
	_sheet = BuildSheet.new()
	_sheet.player = _player
	_sheet.progression = progression
	_root.add_child(_sheet)
	_sheet.setup()
	_sheet.tree_exiting.connect(_close_sheet)

func _close_sheet() -> void:
	controls.enabled = true
	if _paused_for_sheet:
		get_tree().paused = false
		_paused_for_sheet = false

func _exit_tree() -> void:
	if _paused_for_sheet:
		get_tree().paused = false

func _on_state_changed() -> void:
	if encounter.state in [EncounterDirector.State.INTERMISSION, EncounterDirector.State.COMPLETE]:
		open_sheet()

func _process(_delta: float) -> void:
	if _status == null:
		return
	_status.text = "HP %d/%d   •   LV %d   •   Snow %d   •   Wave %d/%d   •   %s" % [_player.health.current, _player.health.maximum, _player.experience.level, progression.wallet.balance(1), encounter.wave, encounter.definition.wave_count, EncounterDirector.State.keys()[encounter.state]]
	_build.text = "Castle built" if builder.has_castle(1) else "Build castle · 10"
	_build.disabled = builder.has_castle(1) or progression.wallet.balance(1) < CastleBuilder.COST or not _player.health.is_alive() or encounter.state in [EncounterDirector.State.COMPLETE, EncounterDirector.State.FAILED]
	_ready_button.disabled = encounter.state != EncounterDirector.State.INTERMISSION or not _player.health.is_alive()
