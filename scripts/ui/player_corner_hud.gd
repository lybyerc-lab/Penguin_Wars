class_name PlayerCornerHUD
extends PanelContainer
## Compact shared desktop/touch readout. Select it to open this player's sheet.
signal selected
var player: PenguinPlayer
var wallet: RunWallet
var _health: ProgressBar
var _title: Label
var _counts: Label

func setup(corner: int, inset: Vector2 = Vector2(18, 18)) -> void:
	var right: bool = corner % 2 == 1
	var bottom: bool = corner >= 2
	anchor_left = 1.0 if right else 0.0
	anchor_right = anchor_left
	anchor_top = 1.0 if bottom else 0.0
	anchor_bottom = anchor_top
	offset_left = -inset.x - 276 if right else inset.x
	offset_right = -inset.x if right else inset.x + 276
	offset_top = -inset.y - 112 if bottom else inset.y
	offset_bottom = -inset.y if bottom else inset.y + 112
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Open character and upgrades"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.10, 0.15, 0.82)
	style.border_color = player.identity.tint
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	var portrait := Control.new()
	portrait.custom_minimum_size = Vector2(62, 86)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	for texture: Texture2D in [preload("res://assets/characters/penguin.svg"), preload("res://assets/characters/scarf.svg")]:
		var art := TextureRect.new()
		art.texture = texture
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if texture.resource_path.ends_with("scarf.svg"):
			art.modulate = player.identity.tint
		portrait.add_child(art)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 19)
	_title.modulate = player.identity.tint
	column.add_child(_title)
	_health = ProgressBar.new()
	_health.custom_minimum_size.y = 23
	_health.show_percentage = false
	_health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = player.identity.tint
	fill.set_corner_radius_all(5)
	_health.add_theme_stylebox_override("fill", fill)
	var health_text := Label.new()
	health_text.name = "Value"
	health_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_text.add_theme_font_size_override("font_size", 15)
	health_text.add_theme_color_override("font_color", Color("102c41"))
	health_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_health.add_child(health_text)
	column.add_child(_health)
	_counts = Label.new()
	_counts.add_theme_font_size_override("font_size", 18)
	column.add_child(_counts)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit()
		accept_event()

func _process(_delta: float) -> void:
	if _health == null:
		return
	_title.text = "P%d  ·  LEVEL %d" % [player.identity.player_id, player.experience.level]
	_health.max_value = player.health.maximum
	_health.value = player.health.current
	_health.get_node("Value").text = "%d / %d" % [player.health.current, player.health.maximum] if player.health.is_alive() else "DOWN"
	_counts.text = "❄  %d flakes" % wallet.balance(player.identity.player_id)
