extends CanvasLayer
var party: PartyRoster
var encounter: EncounterDirector
var progression: RunProgression
var builder: CastleBuilder
var _sheet: BuildSheet
var _status: Label

func setup() -> void:
	for player: PenguinPlayer in party.members():
		var card := PlayerCornerHUD.new()
		card.player = player
		card.wallet = progression.wallet
		add_child(card)
		card.setup(player.identity.player_id - 1)
		card.selected.connect(func() -> void: open_sheet(player))
	_status = Label.new()
	_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_status.offset_left = -230
	_status.offset_right = 230
	_status.offset_top = 18
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 18)
	_status.add_theme_color_override("font_shadow_color", Color("102c41"))
	_status.add_theme_constant_override("shadow_offset_y", 2)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status)
	add_child(LocationBanner.new())

func open_sheet(player: PenguinPlayer) -> void:
	if is_instance_valid(_sheet):
		return
	_sheet = BuildSheet.new()
	_sheet.player = player
	_sheet.progression = progression
	_sheet.builder = builder
	add_child(_sheet)
	_sheet.setup()

func _process(_delta: float) -> void:
	if _status == null:
		return
	if progression.in_town:
		_status.text = "FROSTFALL TOWN · EXPEDITION CAMP"
		return
	var phase: String = "SHOP · OPEN YOUR PENGUIN CARD" if encounter.state == EncounterDirector.State.INTERMISSION else EncounterDirector.State.keys()[encounter.state]
	_status.text = "WAVE %d/%d  ·  %s" % [encounter.wave, encounter.definition.wave_count, phase]
