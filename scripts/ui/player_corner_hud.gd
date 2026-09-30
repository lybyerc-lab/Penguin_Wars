class_name PlayerCornerHUD
extends PanelContainer
signal selected

const CARD_SIZE := Vector2(252, 64)
const CARD_GAP: float = 16.0
const LOW_HEALTH: float = 0.35
const SCRIM: Texture2D = preload("res://assets/ui/hud_v2/hud_card_scrim.png")
const PORTRAIT: Texture2D = preload("res://assets/ui/hud_v2/hud_portrait_penguin_base.png")
const SCARF: Texture2D = preload("res://assets/ui/hud_v2/hud_portrait_penguin_scarf.png")
const MEDALLION: Texture2D = preload("res://assets/ui/hud_v2/hud_medallion_back.png")
const RING: Texture2D = preload("res://assets/ui/hud_v2/hud_medallion_ring.png")
const SNOW: Texture2D = preload("res://assets/ui/hud_v2/hud_snowflake.png")

var player: PenguinPlayer
var wallet: RunWallet
var _health: ProgressBar
var _title: Label
var _counts: Label
var _weapon_row: HBoxContainer
var _weapon_slots: Array[PanelContainer] = []
var _toast: Label
var _toast_time: float = 0.0
var _known_slots: Array[StringName] = []
var _loading: bool = true

func setup(index: int, inset: Vector2 = Vector2(18, 12)) -> void:
	var right_group: bool = index >= 2
	anchor_left = 1.0 if right_group else 0.0
	anchor_right = anchor_left
	anchor_top = 0.0
	anchor_bottom = 0.0
	var lane: int = index if index < 2 else 3 - index
	if right_group:
		offset_right = -inset.x - lane * (CARD_SIZE.x + CARD_GAP)
		offset_left = offset_right - CARD_SIZE.x
	else:
		offset_left = inset.x + lane * (CARD_SIZE.x + CARD_GAP)
		offset_right = offset_left + CARD_SIZE.x
	offset_top = inset.y
	offset_bottom = inset.y + CARD_SIZE.y
	custom_minimum_size = CARD_SIZE
	theme = preload("res://resources/ui/hud_v2_theme.tres")
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Open character and upgrades"
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var scrim := TextureRect.new()
	scrim.texture = SCRIM
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	var medallion := Control.new()
	medallion.name = "Medallion"
	medallion.position = Vector2(3, 5)
	medallion.size = Vector2(52, 52)
	medallion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(medallion)
	_add_art(medallion, MEDALLION, Vector2(2, 2), Vector2(48, 48), Color.WHITE)
	_add_art(medallion, PORTRAIT, Vector2(4, 4), Vector2(44, 44), Color.WHITE)
	_add_art(medallion, SCARF, Vector2(4, 4), Vector2(44, 44), player.identity.tint)
	_add_art(medallion, RING, Vector2.ZERO, Vector2(52, 52), player.identity.tint)
	var level := Label.new()
	level.name = "Level"
	level.position = Vector2(34, 34)
	level.size = Vector2(19, 19)
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level.add_theme_font_size_override("font_size", 10)
	level.add_theme_color_override("font_color", Color.WHITE)
	var badge := StyleBoxFlat.new()
	badge.bg_color = Color("0f2233")
	badge.border_color = Color("8fe6f2")
	badge.set_border_width_all(1)
	badge.set_corner_radius_all(10)
	level.add_theme_stylebox_override("normal", badge)
	medallion.add_child(level)
	_title = Label.new()
	_title.position = Vector2(61, 5)
	_title.size = Vector2(26, 18)
	_title.add_theme_font_size_override("font_size", 12)
	_title.add_theme_color_override("font_color", player.identity.tint)
	add_child(_title)
	_health = ProgressBar.new()
	_health.position = Vector2(88, 8)
	_health.size = Vector2(138, 10)
	_health.show_percentage = false
	_health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color("0f2233", 0.78)
	background.set_corner_radius_all(5)
	_health.add_theme_stylebox_override("background", background)
	add_child(_health)
	var snow := TextureRect.new()
	snow.texture = SNOW
	snow.position = Vector2(61, 27)
	snow.size = Vector2(14, 14)
	snow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	snow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(snow)
	_counts = Label.new()
	_counts.position = Vector2(77, 25)
	_counts.size = Vector2(32, 18)
	_counts.add_theme_font_size_override("font_size", 11)
	_counts.add_theme_color_override("font_color", Color("dff8ff"))
	add_child(_counts)
	_weapon_row = HBoxContainer.new()
	_weapon_row.name = "Weapons"
	_weapon_row.position = Vector2(105, 31)
	_weapon_row.size = Vector2(141, 22)
	_weapon_row.add_theme_constant_override("separation", 3)
	_weapon_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_weapon_row)
	for slot: int in range(WeaponRack.DEFAULT_CAPACITY):
		var frame := PanelContainer.new()
		frame.name = "Slot%d" % slot
		frame.custom_minimum_size = Vector2(19, 19)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(icon)
		_weapon_row.add_child(frame)
		_weapon_slots.append(frame)
	_toast = Label.new()
	_toast.position = Vector2(58, 47)
	_toast.size = Vector2(178, 16)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 10)
	_toast.add_theme_color_override("font_color", Color("ffc766"))
	_toast.visible = false
	add_child(_toast)
	_snapshot_slots()
	if player.weapon_rack != null:
		player.weapon_rack.changed.connect(_on_rack_changed)
	call_deferred("_finish_loading")

func _add_art(parent: Control, texture: Texture2D, pos: Vector2, art_size: Vector2, tint: Color) -> void:
	var art := TextureRect.new()
	art.texture = texture
	art.position = pos
	art.size = art_size
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.modulate = tint
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)

func _finish_loading() -> void:
	_loading = false

func _snapshot_slots() -> void:
	_known_slots.clear()
	if player == null or player.weapon_rack == null:
		return
	for definition: WeaponDefinition in player.weapon_rack.slots():
		_known_slots.append(definition.id if definition != null else &"")

func _on_rack_changed() -> void:
	var improved: bool = false
	if not _loading:
		var slots: Array[WeaponDefinition] = player.weapon_rack.slots()
		for index: int in range(mini(slots.size(), _known_slots.size())):
			if slots[index] != null and slots[index].id != _known_slots[index]:
				improved = true
				break
	_snapshot_slots()
	if improved:
		_toast.text = "WEAPON ACQUIRED"
		_toast_time = 2.2
		_toast.visible = true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit()
		accept_event()

func _process(delta: float) -> void:
	if _health == null or player == null:
		return
	var pid: int = player.identity.player_id
	_title.text = "P%d" % pid
	($Medallion/Level as Label).text = str(player.experience.level)
	_health.max_value = player.health.maximum
	_health.value = player.health.current
	var ratio: float = player.health.current / maxf(1.0, player.health.maximum)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("ff6b6b") if ratio <= LOW_HEALTH else player.identity.tint
	fill.set_corner_radius_all(5)
	_health.add_theme_stylebox_override("fill", fill)
	_counts.text = str(wallet.balance(pid) if wallet != null else 0)
	for slot: int in range(_weapon_slots.size()):
		var definition: WeaponDefinition = player.weapon_rack.weapon_at(slot)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("193e51", 0.82) if definition != null else Color("102a39", 0.60)
		style.border_color = Color("ffc766") if definition != null else Color("46616d", 0.65)
		style.set_border_width_all(1)
		style.set_corner_radius_all(10)
		_weapon_slots[slot].add_theme_stylebox_override("panel", style)
		var icon := _weapon_slots[slot].get_node("Icon") as TextureRect
		icon.texture = definition.icon_texture if definition != null and definition.icon_texture != null else (definition.held_texture if definition != null else null)
	if _toast_time > 0.0:
		_toast_time = maxf(0.0, _toast_time - delta)
		_toast.visible = _toast_time > 0.0
		_toast.modulate.a = minf(1.0, minf(_toast_time / 0.4, (2.2 - _toast_time) / 0.2))
