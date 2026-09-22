extends Node2D
## EXPERIMENT — SmartShape2D evaluation spike. Not a production room, not wired
## into any cave, and not reachable from Expedition.
##
## Composition root for one disposable Frozen Coast room, wired exactly like
## TestArena: RunSession connects the systems and RoomSpace.apply() hands each
## of them its space from `room`. That RoomDefinition is the only geography
## authority here — bounds, entry, exits and supply points all come from it.
##
## Everything under Terrain is SmartShape dressing. Nothing reads gameplay
## values from those nodes and they hold none. Terrain/ShelfCollision carries
## the editor-baked collision SmartShape can generate, and it ships INERT (no
## layer, no mask): switching it on would make SmartShape decide where the
## party may walk, which is exactly the authority this spike must not grant.
## verify_frozen_coast.gd switches it on only to measure it.

@export_range(1, 4) var player_count: int = 2
@export var room: RoomDefinition = preload("res://experiments/smartshape_frozen_coast/frozen_coast_room.tres")

@onready var party: PartyRoster = $Party
@onready var encounter: EncounterDirector = $Encounter
@onready var progression: RunProgression = $Progression

func _ready() -> void:
	var session := RunSession.new()
	session.party = party
	session.wallet = $Wallet
	session.progression = progression
	session.encounter = encounter
	session.loot = $Loot
	session.builder = $Builder
	session.camera = $Camera
	session.actor_root = $Actors
	session.wire()
	if not session.spawn_party(player_count, room.entry_point):
		return
	RoomSpace.apply(room, party, encounter, $Builder, $Loot, $Camera, null, $Actors)
	for spec: RoomExit in room.exits:
		# The same construction Expedition uses. Travel belongs to Expedition, and
		# this prototype has nowhere to go, so `travelled` is left unconnected.
		var gate := PartyGate.new()
		gate.exit = spec
		gate.party = party
		gate.palette = int(room.palette)
		gate.locked = room.has_encounter()
		$Places.add_child(gate)
		gate.place_at_wall(room.bounds)
	# A room with no fight still stocks its supplies, as Expedition does.
	$Loot.resupply()
	$HUD.party = party
	$HUD.encounter = encounter
	$HUD.progression = progression
	$HUD.builder = $Builder
	$HUD.location = room.display_name
	$HUD.setup()

func gates() -> Array[PartyGate]:
	var found: Array[PartyGate] = []
	for node: Node in $Places.get_children():
		if node is PartyGate:
			found.append(node)
	return found
