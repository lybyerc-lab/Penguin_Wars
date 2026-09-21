class_name RunSession
extends RefCounted
## One run's wiring. The scene owns the nodes; this class connects them, so the
## standalone arena slice and the town/cave expedition share a single
## composition path and cannot drift apart. Nothing here is a singleton: every
## reference is handed in by the scene that owns it.

const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
const COLORS: Array[Color] = [Color("58dfed"), Color("ffcb77"), Color("bc9aff"), Color("a9e886")]
const CLEAVER: WeaponDefinition = preload("res://resources/weapons/fish_cleaver.tres")
## Spacing between penguins when the party is placed at a room entrance.
const FORMATION: float = 80.0

var party: PartyRoster
var wallet: RunWallet
var progression: RunProgression
var encounter: EncounterDirector
var loot: ArenaLoot
var builder: CastleBuilder
var camera: PartyCamera
var actor_root: Node2D
var mobile: bool = false

func wire() -> void:
	progression.party = party
	progression.wallet = wallet
	progression.encounter = encounter
	progression.party_ready.connect(encounter.advance_wave)
	encounter.party = party
	encounter.actor_root = actor_root
	loot.party = party
	loot.wallet = wallet
	loot.progression = progression
	loot.actor_root = actor_root
	loot.encounter = encounter
	encounter.loot_available.connect(loot.enemy_drop)
	encounter.state_changed.connect(loot.on_encounter_changed)
	encounter.wave_cleared.connect(loot.bank_uncollected)
	encounter.wave_cleared.connect(progression.finish_wave)
	builder.party = party
	builder.wallet = wallet
	builder.actor_root = actor_root
	builder.encounter = encounter
	camera.party = party
	camera.mobile_layout = mobile

## Returns false when a slot could not be registered, so the caller can abort
## setup instead of running with a half-built party.
func spawn_party(count: int, entry: Vector2) -> bool:
	for index: int in range(count):
		var player := PLAYER_SCENE.instantiate() as PenguinPlayer
		player.identity = PlayerIdentity.new()
		player.identity.player_id = index + 1
		player.identity.local_slot = index
		player.identity.device_id = index
		player.identity.tint = COLORS[index]
		if index % 2 == 1:
			player.get_node("Weapon").definition = CLEAVER
		player.position = _slot(entry, index, count)
		actor_root.add_child(player)
		if not party.register(player):
			push_error("Cannot register party member %d" % player.identity.player_id)
			player.queue_free()
			return false
		progression.bind_player(player)
	return true

## Players keep their health, stats, levels and wallets across a room change.
## Enemies, shots, drops and built structures belong to the room they were in.
func clear_room_actors() -> void:
	for node: Node in actor_root.get_children():
		if node is PenguinPlayer:
			continue
		# Removed as well as freed, so the old room cannot act for one more
		# frame while the new one is being built.
		actor_root.remove_child(node)
		node.queue_free()

func place_party(entry: Vector2) -> void:
	var members: Array[PenguinPlayer] = party.members()
	for index: int in range(members.size()):
		members[index].position = _slot(entry, index, members.size())

func _slot(entry: Vector2, index: int, count: int) -> Vector2:
	return entry + Vector2((index - (count - 1) * 0.5) * FORMATION, 0.0)
