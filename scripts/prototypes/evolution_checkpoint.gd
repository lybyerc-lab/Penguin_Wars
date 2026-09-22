extends "res://scripts/arena/test_arena.gd"
## A contained progression proof: wave five resolves one inventory-owned
## maturation event, then wave six uses the resulting rack loadout.

const LANCE_I: WeaponDefinition = preload("res://resources/weapons/ice_lance.tres")
const CLEAVER_I: WeaponDefinition = preload("res://resources/weapons/fish_cleaver.tres")
const CHECKPOINT_ENCOUNTER: EncounterDefinition = preload("res://resources/encounters/evolution_checkpoint.tres")
const CHECKPOINT_WAVE: int = 5

var _checkpoint_resolved: bool = false
var _last_changes: Array[WeaponMaturation] = []
var _notice: PanelContainer
var _notice_text: Label

func _ready() -> void:
	# TestArena applies its RoomDefinition during setup, and the room normally
	# owns the three-wave Ice Field. Keep that composition path while replacing
	# only this prototype room's encounter data before RunSession starts it.
	var checkpoint_room := room.duplicate() as RoomDefinition
	checkpoint_room.encounter = CHECKPOINT_ENCOUNTER
	room = checkpoint_room
	super._ready()
	if party == null or encounter == null:
		return
	for player: PenguinPlayer in party.members():
		player.configure_weapon_loadout([LANCE_I, LANCE_I, CLEAVER_I, CLEAVER_I])
	_setup_notice()
	encounter.wave_cleared.connect(_on_wave_cleared)
	encounter.state_changed.connect(_on_encounter_state_changed)

func checkpoint_resolved() -> bool:
	return _checkpoint_resolved

func last_changes() -> Array[WeaponMaturation]:
	return _last_changes.duplicate()

func checkpoint_notice_visible() -> bool:
	return _notice != null and _notice.visible

func checkpoint_presentation_text() -> String:
	return _notice_text.text if _notice_text != null else ""

func _on_wave_cleared(wave_number: int) -> void:
	if wave_number != CHECKPOINT_WAVE or _checkpoint_resolved:
		return
	_checkpoint_resolved = true
	_last_changes.clear()
	for player: PenguinPlayer in party.members():
		_last_changes.append_array(player.weapon_rack.resolve_maturation_once())
	_show_checkpoint(_last_changes)

func _on_encounter_state_changed() -> void:
	if _notice != null and encounter.wave >= CHECKPOINT_WAVE + 1 and encounter.state == EncounterDirector.State.SPAWNING:
		_notice.visible = false

func _setup_notice() -> void:
	var layer := CanvasLayer.new()
	layer.name = "EvolutionPresentation"
	layer.layer = 12
	add_child(layer)
	_notice = PanelContainer.new()
	_notice.name = "CheckpointNotice"
	_notice.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notice.position = Vector2(-230.0, 74.0)
	_notice.size = Vector2(460.0, 108.0)
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("17263ce8")
	panel_style.border_color = Color("ffd56b")
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	_notice.add_theme_stylebox_override("panel", panel_style)
	_notice_text = Label.new()
	_notice_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_notice_text.add_theme_font_size_override("font_size", 21)
	_notice_text.add_theme_color_override("font_color", Color("fff2c4"))
	_notice_text.add_theme_color_override("font_outline_color", Color("203553"))
	_notice_text.add_theme_constant_override("outline_size", 6)
	_notice.add_child(_notice_text)
	layer.add_child(_notice)
	_notice.visible = false

func _show_checkpoint(changes: Array[WeaponMaturation]) -> void:
	if changes.is_empty():
		return
	var lines := PackedStringArray(["EVOLUTION CHECKPOINT"])
	for change: WeaponMaturation in changes:
		lines.append("%s %s -> %s" % [change.family_id.capitalize(), change.previous_definition.tier_label(), change.resulting_definition.tier_label()])
	_notice_text.text = "\n".join(lines)
	_notice.visible = true
