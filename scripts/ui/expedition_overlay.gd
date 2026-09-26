class_name ExpeditionOverlay
extends CanvasLayer
## Town and route readout. Desktop keeps the existing passive service cards.
## Mobile uses one large top card opened from the context action button.

const KEYS: Dictionary = {
	1: ["Q", "E", "T"],
	2: ["ENTER", "SHIFT", "."],
	3: ["PAD A", "PAD B", "PAD RB"],
	4: ["PAD A", "PAD B", "PAD RB"],
}

var party: PartyRoster
var market: TownMarket
var journal: RunJournal
var services: Array[TownService] = []
var banner: String = ""
var mobile_layout: bool = false

var _row: HBoxContainer
var _banner_label: Label
var _cards: Dictionary = {}
var _mobile_open: Dictionary = {}

func setup() -> void:
	var service_column := VBoxContainer.new()
	if mobile_layout:
		var viewport_width: float = get_viewport().get_visible_rect().size.x
		var panel_width: float = clampf(viewport_width * 0.52, 620.0, 820.0)
		service_column.set_anchors_preset(Control.PRESET_CENTER_TOP)
		service_column.offset_left = -panel_width * 0.5
		service_column.offset_right = panel_width * 0.5
		service_column.offset_top = 82
		service_column.offset_bottom = 320
	else:
		service_column.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		service_column.offset_top = -230
		service_column.offset_bottom = -86
	service_column.add_theme_constant_override("separation", 6)
	service_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(service_column)

	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 12)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	service_column.add_child(_row)

	# Route/arrival copy stays low and unobtrusive. Only service interaction cards
	# move to the large mobile top position.
	_banner_label = Label.new()
	_banner_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_banner_label.offset_left = 300
	_banner_label.offset_right = -300
	_banner_label.offset_top = -72
	_banner_label.offset_bottom = -48
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_size_override("font_size", 14 if not mobile_layout else 16)
	_banner_label.add_theme_color_override("font_color", Color("cfe9ef"))
	_banner_label.add_theme_color_override("font_outline_color", Color("102c41"))
	_banner_label.add_theme_constant_override("outline_size", 3)
	_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner_label)

	for player: PenguinPlayer in party.members():
		_add_card(player)

func _add_card(player: PenguinPlayer) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.09, 0.14, 0.96)
	style.border_color = player.identity.tint
	style.border_width_left = 4
	style.set_corner_radius_all(10 if mobile_layout else 8)
	style.content_margin_left = 22 if mobile_layout else 14
	style.content_margin_right = 22 if mobile_layout else 14
	style.content_margin_top = 14 if mobile_layout else 8
	style.content_margin_bottom = 14 if mobile_layout else 8
	panel.add_theme_stylebox_override("panel", style)
	panel.visible = false
	if mobile_layout:
		panel.custom_minimum_size.x = clampf(get_viewport().get_visible_rect().size.x * 0.52, 620.0, 820.0)
	_row.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8 if mobile_layout else 4)
	panel.add_child(content)

	var title := Label.new()
	title.modulate = player.identity.tint
	title.add_theme_font_size_override("font_size", 22 if mobile_layout else 15)
	content.add_child(title)

	var body := Label.new()
	body.add_theme_font_size_override("font_size", 18 if mobile_layout else 13)
	body.add_theme_color_override("font_color", Color("e3f2f6") if mobile_layout else Color("cddfe8"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if mobile_layout else TextServer.AUTOWRAP_OFF
	content.add_child(body)

	var offers := HBoxContainer.new()
	offers.alignment = BoxContainer.ALIGNMENT_CENTER
	offers.add_theme_constant_override("separation", 10)
	content.add_child(offers)
	var buttons: Array[Button] = []
	for index: int in range(3):
		var button := Button.new()
		button.custom_minimum_size = Vector2(190, 56)
		button.add_theme_font_size_override("font_size", 16)
		button.visible = false
		button.pressed.connect(_mobile_offer_pressed.bind(player.identity.player_id, index))
		offers.add_child(button)
		buttons.append(button)

	var note := Label.new()
	note.add_theme_font_size_override("font_size", 16 if mobile_layout else 12)
	note.add_theme_color_override("font_color", Color("f4d58d"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if mobile_layout else HORIZONTAL_ALIGNMENT_LEFT
	content.add_child(note)

	_cards[player.identity.player_id] = {
		"panel": panel,
		"title": title,
		"body": body,
		"note": note,
		"buttons": buttons,
	}

func service_at(player_id: int) -> TownService:
	for service: TownService in services:
		if not is_instance_valid(service):
			continue
		for occupant: PenguinPlayer in service.occupants():
			if occupant.identity.player_id == player_id:
				return service
	return null

func toggle_mobile_service(player_id: int) -> void:
	if not mobile_layout:
		return
	if service_at(player_id) == null:
		_mobile_open.erase(player_id)
		return
	_mobile_open[player_id] = not bool(_mobile_open.get(player_id, false))

func mobile_service_open(player_id: int) -> bool:
	return bool(_mobile_open.get(player_id, false))

func _process(_delta: float) -> void:
	if _banner_label == null:
		return
	_banner_label.text = banner
	for player: PenguinPlayer in party.members():
		var id: int = player.identity.player_id
		var card: Dictionary = _cards.get(id, {})
		if card.is_empty():
			continue
		var service: TownService = service_at(id)
		if service == null:
			_mobile_open.erase(id)
			card["panel"].visible = false
			market.clear_note(id)
			continue

		card["panel"].visible = bool(_mobile_open.get(id, false)) if mobile_layout else true
		card["title"].text = "P%d  ·  %s  ·  %s" % [id, service.title, service.keeper]
		card["body"].text = _body(id, service)
		card["note"].text = market.note(id)
		_update_mobile_buttons(id, service, card)

func _update_mobile_buttons(player_id: int, service: TownService, card: Dictionary) -> void:
	var buttons: Array = card["buttons"]
	if not mobile_layout or service.kind == TownService.Kind.TOWN_HALL:
		for button: Button in buttons:
			button.visible = false
		return
	var offers: Array[TownMarket.Offer] = market.offers(service.kind)
	for index: int in range(buttons.size()):
		var button: Button = buttons[index]
		button.visible = index < offers.size()
		if not button.visible:
			continue
		var offer: TownMarket.Offer = offers[index]
		button.text = "%s\n%d Snow" % [offer.label, offer.cost]
		button.modulate = Color.WHITE if market.can_afford(player_id, offer) else Color(0.72, 0.76, 0.8)

func _mobile_offer_pressed(player_id: int, index: int) -> void:
	if not mobile_layout:
		return
	var service: TownService = service_at(player_id)
	if service == null or service.kind == TownService.Kind.TOWN_HALL:
		return
	market.buy(player_id, service.kind, index)

func _body(player_id: int, service: TownService) -> String:
	if service.kind == TownService.Kind.TOWN_HALL:
		return "\n".join(journal.town_hall_lines())
	var lines := PackedStringArray()
	var offers: Array[TownMarket.Offer] = market.offers(service.kind)
	if mobile_layout:
		for offer: TownMarket.Offer in offers:
			lines.append("%s — %s" % [offer.label, offer.detail])
		return "\n".join(lines)
	var keys: Array = KEYS.get(player_id, KEYS[1])
	for index: int in range(offers.size()):
		var offer: TownMarket.Offer = offers[index]
		var mark: String = "·" if market.can_afford(player_id, offer) else "×"
		lines.append("%s  [%s]  %s — %s  ·  %d Snow" % [mark, keys[index], offer.label, offer.detail, offer.cost])
	return "\n".join(lines)
