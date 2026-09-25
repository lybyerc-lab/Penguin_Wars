class_name TownHub
extends RefCounted
## Builds the town's contents. One town exists, so its layout is a table here
## rather than room data; a second town would move this into RoomDefinition
## alongside bounds and supply points.

const SERVICES: Array[Dictionary] = [
	{"kind": TownService.Kind.SHOP, "title": "Fisher's Stall", "keeper": "Marra, trader", "at": Vector2(475, -18), "focus": Vector2(665, -215), "tint": Color("f0c987")},
	{"kind": TownService.Kind.NURSE, "title": "Nurse's Hut", "keeper": "Sister Pell", "at": Vector2(-644, 670), "focus": Vector2(-677, 488), "tint": Color("8fe0c2")},
	{"kind": TownService.Kind.BLACKSMITH, "title": "Cold Forge", "keeper": "Odda, smith", "at": Vector2(-715, -95), "focus": Vector2(-716, -323), "tint": Color("e79a7a")},
	{"kind": TownService.Kind.TOWN_HALL, "title": "Town Hall", "keeper": "Elder Bramblefoot", "at": Vector2(44, -470), "focus": Vector2(44, -760), "tint": Color("a9bdf0")},
]

static func build(into: Node2D, party: PartyRoster) -> Array[TownService]:
	var placed: Array[TownService] = []
	for entry: Dictionary in SERVICES:
		var service := TownService.new()
		service.kind = entry["kind"]
		service.title = entry["title"]
		service.keeper = entry["keeper"]
		service.tint = entry["tint"]
		service.party = party
		service.position = entry["at"]
		service.camera_focus_point = entry["focus"]
		service.structure_visible = false
		into.add_child(service)
		placed.append(service)
	return placed
