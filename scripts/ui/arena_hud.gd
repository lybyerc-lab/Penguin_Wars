extends CanvasLayer
## Shared HUD V2. Arrival, combat, clear and route guidance share one small
## top-centre surface instead of accumulating permanent labels.

const ARRIVAL_DURATION: float = 2.75
const CLEAR_DURATION: float = 3.0
var party: PartyRoster
var encounter: EncounterDirector
var progression: RunProgression
var builder: CastleBuilder
var location: String = "Frostfall Bay"
var _header: VBoxContainer
var _location_label: Label
var _wave_label: Label
var _timer_label: Label
var _cards: Array[PlayerCornerHUD] = []
var _sheet: BuildSheet
var _arrival_left: float = 0.0
var _clear_left: float = 0.0
var _clear_hint: String = ""
var _last_state: int = -1

func setup() -> void:
	if party != null:
		var members: Array[PenguinPlayer] = party.members()
		for index: int in range(members.size()):
			var card := PlayerCornerHUD.new()
			card.player = members[index]
			card.wallet = progression.wallet if progression != null else null
			add_child(card)
			card.setup(index)
			card.selected.connect(func() -> void: open_sheet(members[index]))
			_cards.append(card)
	_header = VBoxContainer.new()
	_header.theme = preload("res://resources/ui/hud_v2_theme.tres")
	_header.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_header.offset_left = -200
	_header.offset_right = 200
	_header.offset_top = 12
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_header)
	_location_label = _label(20, Color("dff8ff"))
	_wave_label = _label(13, Color("bdeef5"))
	_timer_label = _label(22, Color.WHITE)
	_header.add_child(_location_label)
	_header.add_child(_wave_label)
	_header.add_child(_timer_label)
	show_arrival(location)

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("0f2233"))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func show_arrival(value: String) -> void:
	location = value
	_arrival_left = ARRIVAL_DURATION
	_clear_left = 0.0

func set_clear_hint(value: String) -> void:
	_clear_hint = value

func open_sheet(player: PenguinPlayer) -> void:
	if is_instance_valid(_sheet): return
	_sheet = BuildSheet.new()
	_sheet.player = player
	_sheet.progression = progression
	add_child(_sheet)
	_sheet.setup()

func _process(delta: float) -> void:
	if _location_label == null: return
	_arrival_left = maxf(0.0, _arrival_left - delta)
	var current_state: int = encounter.state if encounter != null else -1
	if current_state == EncounterDirector.State.COMPLETE and _last_state != current_state:
		_clear_left = CLEAR_DURATION
	_clear_left = maxf(0.0, _clear_left - delta)
	_last_state = current_state
	if _arrival_left > 0.0:
		var parts := location.split(" · ", false, 1)
		_location_label.text = parts[0].to_upper()
		_wave_label.text = parts[1].to_upper() if parts.size() > 1 else "ARRIVAL"
		_timer_label.visible = false
		return
	_location_label.text = ""
	if progression != null and progression.in_town:
		_wave_label.text = "EXPEDITION CAMP"
		_timer_label.visible = false
		return
	if encounter == null or encounter.definition == null or encounter.state == EncounterDirector.State.READY:
		_wave_label.text = "EXPLORING"
		_timer_label.visible = false
		return
	if encounter.state == EncounterDirector.State.COMPLETE:
		_wave_label.text = (location.split(" · ")[-1] + " CLEAR").to_upper() if _clear_left > 0.0 else ""
		_timer_label.text = _clear_hint if _clear_left > 0.0 else ""
		_timer_label.visible = _clear_left > 0.0 and not _clear_hint.is_empty()
		return
	if encounter.uses_timed_waves():
		_update_timed_wave()
		return
	_timer_label.visible = false
	match encounter.state:
		EncounterDirector.State.INTERMISSION: _wave_label.text = "WAVE %d CLEAR" % encounter.wave
		EncounterDirector.State.BOSS: _wave_label.text = "WAVE %d / %d · BOSS" % [encounter.wave, encounter.definition.wave_count]
		EncounterDirector.State.FAILED: _wave_label.text = "ROUTED"
		_: _wave_label.text = "WAVE %d / %d" % [encounter.wave, encounter.definition.wave_count]

func _update_timed_wave() -> void:
	_timer_label.visible = true
	match encounter.state:
		EncounterDirector.State.SPAWNING:
			_wave_label.text = "WAVE %d / %d" % [encounter.wave, encounter.definition.wave_count]
			_timer_label.text = _clock(encounter.wave_time_remaining())
		EncounterDirector.State.INTERMISSION:
			_wave_label.text = "WAVE %d CLEAR" % encounter.wave
			_timer_label.text = "NEXT %.1f" % encounter.intermission_time_remaining()
		EncounterDirector.State.FAILED:
			_wave_label.text = "ROUTED"
			_timer_label.visible = false
		_:
			_wave_label.text = "WAVE %d / %d" % [encounter.wave, encounter.definition.wave_count]
			_timer_label.visible = false

func _clock(seconds: float) -> String:
	var total: int = ceili(maxf(0.0, seconds))
	return "%d:%02d" % [total / 60, total % 60]
