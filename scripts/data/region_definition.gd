class_name RegionDefinition
extends Resource
## A place the party operates out of: one town, an optional outdoor expedition
## route, and the caves reachable from it. Expedition remains the only travel
## authority; this resource only answers "what geography exists here".
##
## No second journey manager lives here. Outdoor route rooms are ordinary
## RoomDefinitions, just like cave rooms, so bounds/exits stay room-owned.

@export var id: StringName = &"region"
@export var display_name: String = "Region"
@export var town: RoomDefinition
## Optional first room of a region's outdoor journey. Empty keeps the legacy
## town -> cave-mouth behavior unchanged.
@export var expedition_entry_id: StringName = &""
@export var expedition_rooms: Array[RoomDefinition] = []
@export var caves: Array[CaveDefinition] = []

func has_expedition() -> bool:
	return expedition_entry_id != &"" and expedition_room(expedition_entry_id) != null

func expedition_room(room_id: StringName) -> RoomDefinition:
	for candidate: RoomDefinition in expedition_rooms:
		if candidate != null and candidate.id == room_id:
			return candidate
	return null

func cave(cave_id: StringName) -> CaveDefinition:
	for candidate: CaveDefinition in caves:
		if candidate != null and candidate.id == cave_id:
			return candidate
	return null

## Everything wrong with this region, so a broken one fails a test rather than
## a session. Empty means playable.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	if town == null:
		found.append("%s has no town room" % id)
	elif town.kind != RoomDefinition.Kind.TOWN:
		found.append("%s town room '%s' is not a town" % [id, town.id])

	var seen_rooms := PackedStringArray()
	for candidate: RoomDefinition in expedition_rooms:
		if candidate == null:
			found.append("%s has an empty expedition room slot" % id)
			continue
		if seen_rooms.has(String(candidate.id)):
			found.append("%s lists expedition room '%s' twice" % [id, candidate.id])
		seen_rooms.append(String(candidate.id))
	if expedition_entry_id != &"" and expedition_room(expedition_entry_id) == null:
		found.append("%s expedition entry '%s' does not resolve" % [id, expedition_entry_id])
	for candidate: RoomDefinition in expedition_rooms:
		if candidate == null:
			continue
		for exit: RoomExit in candidate.exits:
			if exit.leads_outside():
				continue
			if expedition_room(exit.target_id) == null and cave(exit.target_id) == null:
				found.append("expedition room '%s' route does not resolve: %s" % [candidate.id, exit.target_id])

	if caves.is_empty():
		found.append("%s has no caves" % id)
	var seen_caves := PackedStringArray()
	for candidate: CaveDefinition in caves:
		if candidate == null:
			found.append("%s has an empty cave slot" % id)
			continue
		if seen_caves.has(String(candidate.id)):
			found.append("%s lists cave '%s' twice" % [id, candidate.id])
		seen_caves.append(String(candidate.id))
		if candidate.entrance() == null:
			found.append("cave '%s' has no entrance room" % candidate.id)
		for unresolved: String in candidate.unresolved_exits():
			found.append("cave '%s' route does not resolve: %s" % [candidate.id, unresolved])
	return found
