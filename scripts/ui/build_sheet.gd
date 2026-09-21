class_name BuildSheet
extends PanelContainer
## Shared character sheet and scrollable upgrade catalog for desktop and touch.
var player: PenguinPlayer
var progression: RunProgression
var _summary: Label
var _offers: Array[Button] = []

func setup() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102c41")
	style.set_corner_radius_all(16)
	style.set_content_margin_all(32)
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "P%d  /  CHARACTER & UPGRADES" % player.identity.player_id
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(110, 60)
	close.pressed.connect(queue_free)
	header.add_child(close)
	_summary = Label.new()
	_summary.add_theme_font_size_override("font_size", 20)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_summary)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	for index: int in range(RunProgression.OPTIONS.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 68)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(func() -> void: progression.choose(player.identity.player_id, index))
		grid.add_child(button)
		_offers.append(button)

func _process(_delta: float) -> void:
	if _summary == null:
		return
	var stats: PlayerStats = player.stats
	var id: int = player.identity.player_id
	_summary.text = "HP %.0f/%.0f · Armor %.0f · Regen %.1f/s · Dodge %.0f%% · Speed %.0f\nDamage +%.0f%% · Melee +%.0f · Ranged +%.0f · Attack speed +%.0f%% · Crit %.0f%% (x1.5)\nHarvest x%.2f · Engineering +%.0f · Pickup +%.0f · Range +%.0f\nSnow %d · Free choices %d · %s" % [player.health.current, player.health.maximum, stats.armor, stats.regeneration, minf(stats.dodge_chance, 60), player.speed, stats.damage_percent, stats.melee_damage, stats.ranged_damage, stats.attack_speed, minf(stats.critical_chance, 100), stats.harvest_multiplier, stats.engineering, stats.pickup_bonus, stats.range_bonus, progression.wallet.balance(id), progression.pending.get(id, 0), "Choose an upgrade" if progression.shop_open() else "Shop opens after this wave"]
	for index: int in range(_offers.size()):
		var price: String = "FREE" if progression.pending.get(id, 0) > 0 else "%d Snow" % progression.price(id, index)
		_offers[index].text = "%s   /   %s" % [RunProgression.OPTIONS[index].display_name, price]
		_offers[index].disabled = not progression.can_choose(id, index) or not player.health.is_alive()
