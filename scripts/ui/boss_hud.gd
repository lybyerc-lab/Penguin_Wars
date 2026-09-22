class_name BossHUD
extends CanvasLayer
var encounter: EncounterDirector
var _root: VBoxContainer
var _name: Label
var _health: ProgressBar

func setup() -> void:
	_root = VBoxContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_root.offset_left = -275
	_root.offset_right = 275
	_root.offset_top = 62
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_name = Label.new()
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_font_size_override("font_size", 20)
	_name.add_theme_color_override("font_shadow_color", Color("102c41"))
	_name.add_theme_constant_override("shadow_offset_y", 2)
	_root.add_child(_name)
	_health = ProgressBar.new()
	_health.custom_minimum_size.y = 22
	_health.show_percentage = false
	_health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_health)
	encounter.boss_started.connect(func(boss: ArenaBoss) -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = boss.definition.tint
		style.set_corner_radius_all(5)
		_health.add_theme_stylebox_override("fill", style))

func _process(_delta: float) -> void:
	if _root == null:
		return
	var boss: ArenaBoss = encounter.active_boss
	_root.visible = encounter.state == EncounterDirector.State.BOSS and is_instance_valid(boss)
	if not _root.visible:
		return
	_name.text = boss.definition.display_name + (" · ENRAGED" if (boss.behavior as BossBehavior).enraged else "")
	_health.max_value = boss.health.maximum
	_health.value = boss.health.current
