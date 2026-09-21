class_name CampaignState
extends Resource
## Everything that should outlive a single run: what has been cleared, what has
## been unlocked, and counters a later meta layer will want. A Resource so a
## file-backed ProfileStore can persist it with ResourceSaver and nothing else
## in the game has to change.
##
## This is data, not a manager. Expedition remains the only thing that moves
## the party; it reads and writes this, and so may a future menu.

@export var cleared_caves: PackedStringArray = PackedStringArray()
## Ids of characters, caves or upgrades earned permanently.
@export var unlocked: PackedStringArray = PackedStringArray()
## Named counters for milestones a campaign layer wants to test against.
@export var milestones: Dictionary = {}
@export var runs_started: int = 0
@export var runs_lost: int = 0
@export var deepest_room: String = ""

func has_cleared(cave_id: StringName) -> bool:
	return cleared_caves.has(String(cave_id))

## Returns true only the first time a cave is recorded.
func record_cave(cave_id: StringName) -> bool:
	if cave_id == &"" or has_cleared(cave_id):
		return false
	cleared_caves.append(String(cave_id))
	return true

func is_unlocked(id: StringName) -> bool:
	return unlocked.has(String(id))

## Returns true only the first time something is unlocked.
func unlock(id: StringName) -> bool:
	if id == &"" or is_unlocked(id):
		return false
	unlocked.append(String(id))
	return true

func milestone(name: StringName) -> int:
	return int(milestones.get(String(name), 0))

func mark(name: StringName, amount: int = 1) -> void:
	if name == &"":
		return
	milestones[String(name)] = milestone(name) + amount
