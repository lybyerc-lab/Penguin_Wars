class_name BossHUD
extends CanvasLayer
## Event-driven presentation for the optional boss phase.
## Subscribes to EncounterDirector and BossActor signals with zero polling.

var encounter: EncounterDirector
var party: PartyRoster
var _root: VBoxContainer
var _name: Label
var _health: ProgressBar
var _active_boss: BossActor

func setup() -> void:
	_root = VBoxContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_root.offset_left = -260
	_root.offset_right = 260
	_root.offset_top = 64.0
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)

	_name = Label.new()
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_font_size_override("font_size", 20)
	_name.add_theme_color_override("font_shadow_color", Color("102c41"))
	_name.add_theme_constant_override("shadow_offset_y", 2)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_name)

	_health = ProgressBar.new()
	_health.custom_minimum_size.y = 22
	_health.show_percentage = false
	_health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_health)

	if encounter != null:
		encounter.boss_started.connect(_on_boss_started)
		encounter.boss_defeated.connect(_on_boss_defeated)

func _on_boss_started(boss: BossActor) -> void:
	if not is_instance_valid(boss):
		return
	_active_boss = boss
	var style := StyleBoxFlat.new()
	style.bg_color = boss.boss_definition.tint if boss.boss_definition != null else Color("58dfed")
	style.set_corner_radius_all(5)
	_health.add_theme_stylebox_override("fill", style)

	var hp: Health = boss.get_node_or_null("Health") as Health
	if hp != null:
		_health.max_value = hp.maximum
		_health.value = hp.current
		hp.changed.connect(_on_health_changed)

	boss.presentation_changed.connect(_on_presentation_changed)
	boss.tree_exiting.connect(_hide_hud)
	_update_presentation()
	_root.visible = true

func _on_boss_defeated(_boss: BossActor) -> void:
	_hide_hud()

func _on_presentation_changed() -> void:
	_update_presentation()

func _update_presentation() -> void:
	if not is_instance_valid(_active_boss):
		return
	var title: String = _active_boss.title()
	var phase: String = _active_boss.phase()
	_name.text = title + (" · " + phase if phase != "" else "")

func _on_health_changed(current: float, maximum: float) -> void:
	_health.max_value = maximum
	_health.value = current

func _hide_hud() -> void:
	_root.visible = false
	_active_boss = null
