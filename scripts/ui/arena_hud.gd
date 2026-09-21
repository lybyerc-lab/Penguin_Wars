extends CanvasLayer
## Shared minimal HUD for arena and expedition combat.
## Displays lightweight center-top location and wave status, while individual
## player vitals float in screen corners via PlayerCornerHUD.

var party: PartyRoster
var encounter: EncounterDirector
var progression: RunProgression
var builder: CastleBuilder
## Where the party is. The HUD is shared by the arena slice and the town.
var location: String = "Frostfall Bay"

var _header: VBoxContainer
var _location_label: Label
var _wave_label: Label
var _cards: Array[PlayerCornerHUD] = []
var _sheet: BuildSheet

func setup() -> void:
	if party != null:
		var members: Array[PenguinPlayer] = party.members()
		for index: int in range(members.size()):
			var player: PenguinPlayer = members[index]
			var card := PlayerCornerHUD.new()
			card.player = player
			card.wallet = progression.wallet if progression != null else null
			add_child(card)
			card.setup(index)
			card.selected.connect(func() -> void: open_sheet(player))
			_cards.append(card)

	_header = VBoxContainer.new()
	_header.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_header.offset_left = -220
	_header.offset_right = 220
	_header.offset_top = 14
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_header)

	_location_label = Label.new()
	_location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_location_label.add_theme_font_size_override("font_size", 18)
	_location_label.add_theme_color_override("font_shadow_color", Color("102c41"))
	_location_label.add_theme_constant_override("shadow_offset_y", 2)
	_location_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(_location_label)

	_wave_label = Label.new()
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.add_theme_font_size_override("font_size", 14)
	_wave_label.add_theme_color_override("font_color", Color("bddfe5"))
	_wave_label.add_theme_color_override("font_shadow_color", Color("102c41"))
	_wave_label.add_theme_constant_override("shadow_offset_y", 1)
	_wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(_wave_label)

func open_sheet(player: PenguinPlayer) -> void:
	if is_instance_valid(_sheet):
		return
	_sheet = BuildSheet.new()
	_sheet.player = player
	_sheet.progression = progression
	add_child(_sheet)
	_sheet.setup()

func _process(_delta: float) -> void:
	if _location_label == null:
		return
	_location_label.text = location.to_upper()
	if progression != null and progression.in_town:
		_wave_label.text = "EXPEDITION CAMP"
		return
	if encounter == null or encounter.definition == null or encounter.state == EncounterDirector.State.READY:
		_wave_label.text = "EXPLORING"
		return

	match encounter.state:
		EncounterDirector.State.INTERMISSION:
			_wave_label.text = "WAVE %d / %d · SHOP / READY" % [encounter.wave, encounter.definition.wave_count]
		EncounterDirector.State.BOSS:
			_wave_label.text = "WAVE %d / %d · BOSS" % [encounter.wave, encounter.definition.wave_count]
		EncounterDirector.State.COMPLETE:
			_wave_label.text = "WAVE %d / %d · CLEARED" % [encounter.wave, encounter.definition.wave_count]
		EncounterDirector.State.FAILED:
			_wave_label.text = "ROUTED"
		_:
			_wave_label.text = "WAVE %d / %d" % [encounter.wave, encounter.definition.wave_count]
