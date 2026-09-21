extends SceneTree
## Real engine integration tests. Exit status is nonzero on any failed check.
var failures: int = 0

class TestInput extends LocalPlayerInput:
	func movement() -> Vector2:
		return Vector2.RIGHT

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var scene: PackedScene = load("res://scenes/arena/test_arena.tscn")
	var arena: Node2D = scene.instantiate()
	root.add_child(arena)
	await process_frame
	var party: PartyRoster = arena.party
	var players: Array[PenguinPlayer] = party.members()
	check(players.size() == 2, "default arena has two players")
	check(not party.register(players[0]), "duplicate IDs rejected")
	check(players[0].identity != players[1].identity, "identity resources are per-player")
	check(party.nearest_alive(players[1].position) == players[1], "nearest target supports P2")
	var original_input: LocalPlayerInput = players[1].input_source
	var test_input := TestInput.new()
	players[1].add_child(test_input)
	players[1].input_source = test_input
	var position_before: Vector2 = players[1].position
	await physics_frame
	await physics_frame
	check(players[1].position.x > position_before.x, "movement command advances player")
	players[1].position = Vector2(10000, 10000)
	await physics_frame
	await physics_frame
	check(players[1].position.x <= 540 and players[1].position.y <= 260, "arena bounds contain player")
	players[1].input_source = original_input
	test_input.queue_free()
	players[1].position = Vector2(40, 40)
	var health: Health = players[0].health
	var deaths: Array[int] = [0]
	health.died.connect(func(_event: DamageEvent) -> void: deaths[0] += 1)
	health.take_damage(DamageEvent.new(-10))
	check(health.current == 100, "negative damage ignored")
	health.take_damage(DamageEvent.new(200))
	health.take_damage(DamageEvent.new(200))
	health.heal(100)
	check(deaths[0] == 1 and health.current == 0, "death once; healing cannot revive")
	check(party.nearest_alive(players[0].position) == players[1], "retarget after death")
	players[1].experience.grant(15)
	check(players[1].experience.level == 3 and players[1].experience.xp == 2, "multiple level-ups preserve overflow")
	check(arena.progression.pending[2] == 2, "level-up queue retains choices")
	arena.encounter.state = EncounterDirector.State.INTERMISSION
	check(arena.progression.choose(2, 0), "upgrade choice accepted")
	check(players[1].weapon.damage_bonus == 3 and players[0].weapon.damage_bonus == 0, "upgrade state isolated")
	check(players[1].weapon.definition.damage == 22, "shared resource remains immutable")
	check(not arena.progression.choose(2, 99), "invalid upgrade rejected")
	# Exercise the actual weapon/target/damage/reward chain.
	var enemy: ArenaEnemy = load("res://scenes/actors/enemy.tscn").instantiate()
	enemy.party = party
	enemy.position = players[1].position + Vector2(80, 0)
	arena.get_node("Actors").add_child(enemy)
	enemy.defeated.connect(func(_actor: ArenaEnemy, _event: DamageEvent) -> void: arena.progression.collect_materials(2, 1))
	var xp_before: int = players[1].experience.xp
	players[1].weapon._physics_process(1.1)
	players[1].weapon._physics_process(1.1)
	check(not enemy.health.is_alive(), "weapon kills target in range")
	check(players[1].experience.xp == xp_before + 1, "enemy death awards XP")
	await process_frame
	# Drive all encounter waves without real-time waiting.
	var director: EncounterDirector = arena.encounter
	director.state = EncounterDirector.State.SPAWNING
	director.auto_advance = true
	for step: int in range(100):
		director._physics_process(10.0)
		for node: Node in get_nodes_in_group("enemies"):
			(node as ArenaEnemy).health.take_damage(DamageEvent.new(1000, 2))
		await process_frame
		if director.state == EncounterDirector.State.COMPLETE:
			break
	check(director.state == EncounterDirector.State.COMPLETE and director.alive_count == 0, "all waves reach completion")
	arena.free()
	# Capacity, game-over, disposal and clean re-entry with four party members.
	arena = scene.instantiate()
	arena.player_count = 4
	root.add_child(arena)
	await process_frame
	check(arena.party.members().size() == 4, "four-player arena supported")
	for player: PenguinPlayer in arena.party.members():
		player.health.take_damage(DamageEvent.new(1000))
	arena.encounter._physics_process(0.1)
	check(arena.encounter.state == EncounterDirector.State.FAILED, "party wipe ends encounter")
	arena.free()
	check(get_nodes_in_group("enemies").is_empty(), "no actors leak across runs")
	print("FOUNDATION TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
