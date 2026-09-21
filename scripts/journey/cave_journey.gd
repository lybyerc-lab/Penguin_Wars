class_name CaveJourney
extends Node
## Session flow: players and their run data survive changes of location.
signal cave_cleared(cave_number: int)
signal location_changed(in_town: bool, cave_number: int)
var party: PartyRoster
var encounter: EncounterDirector
var progression: RunProgression
var loot: ArenaLoot
var builder: CastleBuilder
var actor_root: Node2D
var cave_number: int = 1
var in_town: bool = false
var _announced: bool = false
var _moving: bool = false
var _base_definition: EncounterDefinition

func setup() -> void:
	_base_definition = encounter.definition.duplicate() as EncounterDefinition
	encounter.state_changed.connect(_on_encounter_changed)

func location_title() -> String:
	if in_town:
		return "FROSTFALL TOWN"
	var names: Array[String] = ["FROSTFALL BAY", "BLUEGLASS HOLLOW", "DEEPFROST PASSAGE"]
	return "%s · CAVE %d" % [names[(cave_number - 1) % names.size()], cave_number]

func can_leave() -> bool:
	return not _moving and not in_town and encounter.state == EncounterDirector.State.COMPLETE

func _on_encounter_changed() -> void:
	# State change follows final-wave payments and reserve banking.
	if can_leave() and not _announced:
		_announced = true
		cave_cleared.emit(cave_number)

func next_cave() -> bool:
	if _moving or (not in_town and not can_leave()):
		return false
	_moving = true
	_clear_room()
	in_town = false
	cave_number += 1
	_announced = false
	progression.begin_cave()
	loot.begin_cave()
	var definition := _base_definition.duplicate() as EncounterDefinition
	definition.base_count += mini(cave_number - 1, 10) * 2
	definition.run_seed += (cave_number - 1) * 97
	encounter.definition = definition
	_place_party(true)
	location_changed.emit(false, cave_number)
	encounter.start()
	_moving = false
	return true

func return_to_town() -> bool:
	if not can_leave():
		return false
	_moving = true
	_clear_room()
	in_town = true
	progression.in_town = true
	progression.ready_players.clear()
	encounter.state = EncounterDirector.State.READY
	_place_party(false)
	location_changed.emit(true, cave_number)
	encounter.state_changed.emit()
	_moving = false
	return true

func _clear_room() -> void:
	loot.bank_uncollected(0)
	for node: Node in actor_root.get_children():
		if node is PenguinPlayer:
			continue
		# Detach immediately so old targets cannot be found during the transition.
		actor_root.remove_child(node)
		node.queue_free()
	builder.castles.clear()
	builder.last_result.clear()

func _place_party(combat: bool) -> void:
	var players: Array[PenguinPlayer] = party.members()
	for index: int in range(players.size()):
		var player: PenguinPlayer = players[index]
		player.position = Vector2((index - (players.size() - 1) * 0.5) * 80, 40)
		player.velocity = Vector2.ZERO
		player.input_source.touch_movement = Vector2.ZERO
		player.input_source.touch_dash_pending = false
		player.weapon.set_physics_process(combat)
