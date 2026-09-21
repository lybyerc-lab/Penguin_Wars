class_name RunSession
extends RefCounted
## One run's wiring. The scene owns the nodes; this class connects them, so the
## standalone arena slice and the town/cave expedition share a single
## composition path and cannot drift apart. Nothing here is a singleton: every
## reference is handed in by the scene that owns it.

const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
## The roster a run uses when nothing else is chosen. A selection screen sets
## `roster` instead; slot N takes roster[N].
const DEFAULT_ROSTER: Array[CharacterDefinition] = [
	preload("res://resources/characters/skua.tres"),
	preload("res://resources/characters/ember.tres"),
	preload("res://resources/characters/vesper.tres"),
	preload("res://resources/characters/sorrel.tres"),
]
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
## Whole-run dials, handed to the systems that read them. Never null.
var modifiers := RunModifiers.new()
## Ordered selection for slots 1..4. Shorter lists wrap.
var roster: Array[CharacterDefinition] = DEFAULT_ROSTER.duplicate()

func wire() -> void:
	encounter.modifiers = modifiers
	progression.modifiers = modifiers
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
	encounter.boss_reward.connect(progression.grant_boss_reward)
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
		var character: CharacterDefinition = roster[index % roster.size()] if not roster.is_empty() else null
		if character != null:
			player.identity.tint = character.tint
			player.identity.character_id = character.id
			if not character.starting_weapons.is_empty() and character.starting_weapons[0] != null:
				player.get_node("Weapon").definition = character.starting_weapons[0]
		player.position = _slot(entry, index, count)
		actor_root.add_child(player)
		if not party.register(player):
			push_error("Cannot register party member %d" % player.identity.player_id)
			player.queue_free()
			return false
		progression.bind_player(player)
		if character != null:
			_apply_character(player, character)
		if modifiers.starting_snowflakes > 0:
			wallet.credit(player.identity.player_id, modifiers.starting_snowflakes)
	return true

## Body, opening stats and rule-changing traits. Runs after the penguin is in
## the tree, so its own @onready nodes exist and apply_upgrade() works.
static func _apply_character(player: PenguinPlayer, character: CharacterDefinition) -> void:
	if not is_equal_approx(character.body_scale, 1.0):
		_scale_body(player, character.body_scale)
	for upgrade: UpgradeDefinition in character.starting_stats:
		if upgrade != null:
			player.apply_upgrade(upgrade)
	for scene: PackedScene in character.traits:
		if scene == null:
			continue
		var rule := scene.instantiate() as CharacterTrait
		if rule == null:
			push_error("Character '%s' has a trait that is not a CharacterTrait" % character.id)
			continue
		player.add_child(rule)
		rule.setup(player)

static func _scale_body(player: PenguinPlayer, scale: float) -> void:
	var visual: Node2D = player.get_node_or_null("CharacterVisual") as Node2D
	if visual != null:
		visual.scale = Vector2.ONE * scale
	var collision: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null and collision.shape is CircleShape2D:
		# The scene's shape is shared between instances; resize a copy.
		var body: CircleShape2D = collision.shape.duplicate()
		body.radius *= scale
		collision.shape = body

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
