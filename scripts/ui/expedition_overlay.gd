class_name ExpeditionOverlay
extends CanvasLayer
## Town and route readout. Panels open by standing in a service zone, so this
## layer only reports what the world already decided; it never owns state.

## The keys that pick wave-shop upgrades also pick service options, so the town
## introduces no new bindings to learn.
const KEYS: Dictionary = {
	1: ["Q", "E", "T"],
	2: ["ENTER", "SHIFT", "."],
	3: ["PAD A", "PAD B", "PAD RB"],
	4: ["PAD A", "PAD B", "PAD RB"],
}

var party: PartyRoster
var market: TownMarket
var journal: RunJournal
## Shared with the expedition, which owns the current room's buildings.
var services: Array[TownService] = []
var banner: String = ""

var _row: HBoxContainer
var _banner_label: Label
var _cards: Dictionary = {}

func setup() -> void:
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	column.offset_top = -230
	column.offset_bottom = -52
	column.add_theme_constant_override("separation", 6)
	column.alignment = BoxContainer.ALIGNMENT_END
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 12)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_row)
	_banner_label = Label.new()
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_size_override("font_size", 14)
	_banner_label.add_theme_color_override("font_color", Color("cfe9ef"))
	_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_banner_label)
	for player: PenguinPlayer in party.members():
		_add_card(player)

func _add_card(player: PenguinPlayer) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.09, 0.14, 0.95)
	style.border_color = player.identity.tint
	style.border_width_left = 4
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.visible = false
	_row.add_child(panel)
	var content := VBoxContainer.new()
	panel.add_child(content)
	var title := Label.new()
	title.modulate = player.identity.tint
	title.add_theme_font_size_override("font_size", 15)
	content.add_child(title)
	var body := Label.new()
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", Color("cddfe8"))
	content.add_child(body)
	var note := Label.new()
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color("f4d58d"))
	content.add_child(note)
	_cards[player.identity.player_id] = {"panel": panel, "title": title, "body": body, "note": note}

## The building a player is standing in, or null.
func service_at(player_id: int) -> TownService:
	for service: TownService in services:
		if not is_instance_valid(service):
			continue
		for occupant: PenguinPlayer in service.occupants():
			if occupant.identity.player_id == player_id:
				return service
	return null

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
		card["panel"].visible = service != null
		if service == null:
			market.clear_note(id)
			continue
		card["title"].text = "P%d  ·  %s  ·  %s" % [id, service.title, service.keeper]
		card["body"].text = _body(id, service)
		card["note"].text = market.note(id)

func _body(player_id: int, service: TownService) -> String:
	if service.kind == TownService.Kind.TOWN_HALL:
		return "\n".join(journal.town_hall_lines())
	var keys: Array = KEYS.get(player_id, KEYS[1])
	var lines := PackedStringArray()
	var offers: Array[TownMarket.Offer] = market.offers(service.kind)
	for index: int in range(offers.size()):
		var offer: TownMarket.Offer = offers[index]
		var mark: String = "·" if market.can_afford(player_id, offer) else "×"
		lines.append("%s  [%s]  %s — %s  ·  %d flakes" % [mark, keys[index], offer.label, offer.detail, offer.cost])
	return "\n".join(lines)
