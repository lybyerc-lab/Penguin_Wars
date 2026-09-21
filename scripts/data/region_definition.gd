class_name RegionDefinition
extends Resource
## A place the party operates out of: one town room and the caves reachable
## from it. Expedition takes a region rather than constants, so a second
## region is a resource, not a code change.
##
## This is data, not a second journey manager: it answers "what exists here",
## never "where is the party now".

@export var id: StringName = &"region"
@export var display_name: String = "Region"
@export var town: RoomDefinition
@export var caves: Array[CaveDefinition] = []

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
	if caves.is_empty():
		found.append("%s has no caves" % id)
	var seen := PackedStringArray()
	for candidate: CaveDefinition in caves:
		if candidate == null:
			found.append("%s has an empty cave slot" % id)
			continue
		if seen.has(String(candidate.id)):
			found.append("%s lists cave '%s' twice" % [id, candidate.id])
		seen.append(String(candidate.id))
		if candidate.entrance() == null:
			found.append("cave '%s' has no entrance room" % candidate.id)
		for unresolved: String in candidate.unresolved_exits():
			found.append("cave '%s' route does not resolve: %s" % [candidate.id, unresolved])
	return found
