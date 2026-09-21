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
	var card := PlayerCornerHUD.new()
	card.player = _player
	card.wallet = progression.wallet
	_root.add_child(card)
	card.setup(0, inset)
	card.selected.connect(open_sheet)
	var actions := VBoxContainer.new()
	actions.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	actions.offset_left = -inset.x - 180
	actions.offset_right = -inset.x
	actions.offset_top = inset.y
	_root.add_child(actions)
	_build = _button("Castle · 10", func() -> void: builder.build(1), actions)
	_ready_button = _button("Next wave", func() -> void: progression.toggle_ready(1), actions)
	_status = Label.new()
	_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_status.offset_left = -180
	_status.offset_right = 180
	_status.offset_top = inset.y
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 20)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_status)
	_root.add_child(LocationBanner.new())
	encounter.state_changed.connect(_on_state_changed)

func _button(text: String, callback: Callable, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180, 56)
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
	_sheet.builder = builder
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
	_status.text = "WAVE %d/%d" % [encounter.wave, encounter.definition.wave_count]
	_build.text = "Castle built" if builder.has_castle(1) else "Build castle · 10"
	_build.disabled = builder.has_castle(1) or progression.wallet.balance(1) < CastleBuilder.COST or not _player.health.is_alive() or encounter.state in [EncounterDirector.State.COMPLETE, EncounterDirector.State.FAILED]
	_ready_button.visible = encounter.state == EncounterDirector.State.INTERMISSION
	_ready_button.disabled = encounter.state != EncounterDirector.State.INTERMISSION or not _player.health.is_alive()
