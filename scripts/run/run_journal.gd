class_name RunJournal
extends Node
## What the town knows. Cave results are recorded here and the town hall reads
## them, so a meeting can react to the last expedition without any system
## reaching into another.

signal changed

var rooms_cleared: int = 0
var caves_cleared: PackedStringArray = PackedStringArray()
var expeditions: int = 0
var routs: int = 0
var deepest_room: String = ""

func begin_expedition(cave: CaveDefinition) -> void:
	expeditions += 1
	if cave != null and deepest_room.is_empty():
		deepest_room = cave.display_name
	changed.emit()

func record_room(room: RoomDefinition) -> void:
	if room == null:
		return
	rooms_cleared += 1
	deepest_room = room.display_name
	changed.emit()

func record_cave(cave: CaveDefinition) -> void:
	if cave == null or caves_cleared.has(String(cave.id)):
		changed.emit()
		return
	caves_cleared.append(String(cave.id))
	changed.emit()

func record_rout() -> void:
	routs += 1
	changed.emit()

func cleared(cave: CaveDefinition) -> bool:
	return cave != null and caves_cleared.has(String(cave.id))

## The town hall meeting. Short, characterful, and different once the party
## has actually been somewhere.
func town_hall_lines() -> PackedStringArray:
	if expeditions == 0:
		return PackedStringArray([
			"Elder Bramblefoot raps the lectern with a flipper.",
			"\"The fish runs are thin and the old ice groans. Something down in the caves is taking more than its share.\"",
			"\"Take the east passage. Come back, that is all the council asks.\"",
		])
	if not caves_cleared.is_empty():
		return PackedStringArray([
			"The hall is warmer than you remember. Someone has put out kelp tea.",
			"\"%s is quiet again,\" says Bramblefoot. \"The nets came up heavy this morning.\"" % deepest_room,
			"\"There are deeper passages. The council is not ready to ask. Yet.\"",
		])
	if routs > 0:
		return PackedStringArray([
			"Bramblefoot studies the frost on the window rather than the party.",
			"\"You came back. That is not nothing.\" A pause. \"%s took a bite out of you.\"" % deepest_room,
			"\"The nurse is in. Go and be mended, then decide for yourselves.\"",
		])
	return PackedStringArray([
		"Bramblefoot leans forward. \"You have been down there. What did you see?\"",
		"\"%s, then. Cleared rooms: %d.\" The elder makes a careful mark." % [deepest_room, rooms_cleared],
		"\"Finish what you started. The council will hold the tea.\"",
	])
