class_name PlayerCornerHUD
extends PanelContainer
## Compact screen-corner readout for 1-4 players. Displays portrait, scarf,
## health bar, level, and personal Snow balance without covering the arena.
signal selected

var player: PenguinPlayer
var wallet: RunWallet
var _health: ProgressBar
var _title: Label
var _counts: Label
var _weapon_row: HBoxContainer
var _weapon_slots: Array[PanelContainer] = []

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
	style.border_color = player.identity.tint if player and player.identity else Color.WHITE
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
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
		if texture.resource_path.ends_with("scarf.svg") and player and player.identity:
			art.modulate = player.identity.tint
		portrait.add_child(art)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 18)
	if player and player.identity:
		_title.modulate = player.identity.tint
	column.add_child(_title)

	_health = ProgressBar.new()
	_health.custom_minimum_size.y = 22
	_health.show_percentage = false
	_health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = player.identity.tint if player and player.identity else Color("58dfed")
	fill.set_corner_radius_all(5)
	_health.add_theme_stylebox_override("fill", fill)

	var health_text := Label.new()
	health_text.name = "Value"
	health_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_text.add_theme_font_size_override("font_size", 14)
	health_text.add_theme_color_override("font_color", Color("102c41"))
	health_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_health.add_child(health_text)
	column.add_child(_health)

	_counts = Label.new()
	_counts.add_theme_font_size_override("font_size", 16)
	column.add_child(_counts)

	# Six compact personal inventory slots. Their visuals are deliberately small:
	# the corner card reports ownership without becoming an inventory screen.
	_weapon_row = HBoxContainer.new()
	_weapon_row.name = "Weapons"
	_weapon_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_weapon_row.add_theme_constant_override("separation", 4)
	column.add_child(_weapon_row)
	for slot: int in range(WeaponRack.DEFAULT_CAPACITY):
		var frame := PanelContainer.new()
		frame.name = "Slot%d" % slot
		frame.custom_minimum_size = Vector2(24, 24)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(icon)
		var empty := Label.new()
		empty.name = "Empty"
		empty.text = "·"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color("6d8997"))
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.add_child(empty)
		_weapon_row.add_child(frame)
		_weapon_slots.append(frame)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit()
		accept_event()

func _process(_delta: float) -> void:
	if _health == null or player == null:
		return
	var pid: int = player.identity.player_id if player.identity else 1
	var lvl: int = player.experience.level if player.experience else 1
	_title.text = "P%d  ·  LEVEL %d" % [pid, lvl]
	_health.max_value = player.health.maximum
	_health.value = player.health.current
	var label_node: Label = _health.get_node_or_null("Value") as Label
	if label_node != null:
		label_node.text = "%d / %d" % [int(player.health.current), int(player.health.maximum)] if player.health.is_alive() else "DOWN"
	var balance: int = wallet.balance(pid) if wallet != null else 0
	_counts.text = "❄  %d Snow" % balance
	for slot: int in range(_weapon_slots.size()):
		var frame: PanelContainer = _weapon_slots[slot]
		var definition: WeaponDefinition = player.weapon_rack.weapon_at(slot) if player.weapon_rack != null else null
		var occupied := definition != null
		var style := StyleBoxFlat.new()
		style.bg_color = Color("193e51") if occupied else Color("102a39")
		style.border_color = definition.tint if occupied else Color("315465")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		frame.add_theme_stylebox_override("panel", style)
		frame.tooltip_text = definition.display_name if occupied else "Empty weapon slot %d" % (slot + 1)
		var icon := frame.get_node_or_null("Icon") as TextureRect
		var empty := frame.get_node_or_null("Empty") as Label
		if icon != null:
			icon.texture = definition.held_texture if occupied else null
		if empty != null:
			empty.visible = not occupied
