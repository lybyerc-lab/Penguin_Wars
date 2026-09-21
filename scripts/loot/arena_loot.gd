class_name ArenaLoot
extends Node
## Composition-owned drop and resupply policy; pickups handle collection.
var party: PartyRoster
var wallet: RunWallet
var progression: RunProgression
var actor_root: Node2D
var encounter: EncounterDirector
var _supplied_wave: int = 0

func begin_cave() -> void:
	_supplied_wave = 0

func on_encounter_changed() -> void:
	if encounter.state != EncounterDirector.State.SPAWNING or encounter.wave == _supplied_wave:
		return
	_supplied_wave = encounter.wave
	# Replace only missing snowmen; intact supply props persist between waves.
	for point: Vector2 in [Vector2(-330, 110), Vector2(330, 110)]:
		var occupied: bool = false
		for node: Node in actor_root.get_children():
			if node is SupplySnowman and node.health.is_alive() and node.position.distance_to(point) < 10:
				occupied = true
		if not occupied:
			var snowman: SupplySnowman = preload("res://scenes/props/supply_snowman.tscn").instantiate()
			snowman.position = point
			snowman.broken.connect(_on_snowman_broken)
			actor_root.add_child(snowman)

func enemy_drop(location: Vector2) -> void:
	spawn_pickup(location, RunPickup.Kind.SNOWFLAKE, 2)

func _on_snowman_broken(location: Vector2) -> void:
	spawn_pickup(location + Vector2(-16, 0), RunPickup.Kind.HEALTH, 25)
	spawn_pickup(location + Vector2(16, 0), RunPickup.Kind.SNOWFLAKE, 3)

func spawn_pickup(location: Vector2, kind: RunPickup.Kind, amount: int) -> RunPickup:
	var pickup := RunPickup.new()
	pickup.party = party
	pickup.kind = kind
	pickup.amount = amount
	pickup.position = actor_root.to_local(location)
	if kind == RunPickup.Kind.SNOWFLAKE:
		pickup.collected.connect(progression.collect_materials)
	actor_root.add_child(pickup)
	return pickup

func bank_uncollected(_wave: int) -> void:
	for node: Node in actor_root.get_children():
		if node is RunPickup and node.kind == RunPickup.Kind.SNOWFLAKE and not node.claimed:
			progression.reserve += node.amount
			node.claimed = true
			node.queue_free()
