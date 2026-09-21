extends SceneTree
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	root.add_child(arena)
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	await physics_frame
	var players: Array[PenguinPlayer] = arena.party.members()
	players[0].position = Vector2(150, 0)
	players[1].position = Vector2(350, 0)
	var charger: ArenaEnemy = load("res://scenes/actors/charging_seal.tscn").instantiate()
	charger.party = arena.party
	arena.get_node("Actors").add_child(charger)
	charger.set_physics_process(false)
	var charge: ChargeBehavior = charger.behavior
	check(charger.health.maximum == 44, "charger scene has its own health")
	check(charge.movement(charger, players[0], 0.01) == Vector2.ZERO and charge.state == ChargeBehavior.State.WINDUP, "charge starts with stationary tell")
	players[0].position = Vector2(150, 100)
	check(charge.movement(charger, players[0], 0.76) == Vector2.RIGHT * 360, "charge locks the warned direction")
	charge.movement(charger, players[0], 0.66)
	check(charge.state == ChargeBehavior.State.RECOVER and not charge.contact_enabled(), "charge leaves a safe punish window")
	charge.movement(charger, players[0], 1.2)
	charge.movement(charger, players[0], 0.01)
	charger.health.take_damage(DamageEvent.new(14, 1, Vector2(90, 0)))
	check(charge.state == ChargeBehavior.State.WINDUP and charger._knockback.x == 90, "lance pushes without cancelling tell")
	charger.health.take_damage(DamageEvent.new(22, 2, Vector2(320, 0)))
	check(charge.state == ChargeBehavior.State.RECOVER, "cleaver interrupts charger")
	var thrower: ArenaEnemy = load("res://scenes/actors/snowball_thrower.tscn").instantiate()
	thrower.party = arena.party
	arena.get_node("Actors").add_child(thrower)
	thrower.set_physics_process(false)
	var ranged: RangedBehavior = thrower.behavior
	players[0].position = Vector2(100, 0)
	check(ranged.movement(thrower, players[0], 0.01).x < 0, "thrower retreats from close player")
	players[0].position = Vector2(450, 0)
	check(ranged.movement(thrower, players[0], 0.01).x > 0, "thrower approaches out-of-range player")
	players[0].position = Vector2(250, 0)
	ranged.movement(thrower, players[0], 1.0)
	check(ranged.state == RangedBehavior.State.WINDUP and get_nodes_in_group("enemy_projectiles").is_empty(), "thrower warns before shot")
	players[0].position = Vector2(250, 100)
	ranged.movement(thrower, players[0], 0.71)
	var shot: EnemySnowball = get_nodes_in_group("enemy_projectiles")[0]
	shot.set_physics_process(false)
	check(shot.direction == Vector2.RIGHT, "snowball does not home after tell")
	check(ranged.state == RangedBehavior.State.RECOVER and not ranged.contact_enabled(), "thrower uses cooldown and no contact damage")
	# Swept shot crosses both players in one step, hitting only the nearer player.
	players[0].position = Vector2(100, 0)
	players[1].position = Vector2(160, 0)
	shot.position = Vector2.ZERO
	shot._physics_process(1.0)
	shot._physics_process(1.0)
	check(players[0].health.current == 90 and players[1].health.current == 100, "swept projectile hits nearest player only once")
	await process_frame
	shot = EnemySnowball.new()
	shot.party = arena.party
	arena.get_node("Actors").add_child(shot)
	shot.set_physics_process(false)
	players[0].health.invulnerable = true
	shot._physics_process(1.0)
	check(players[0].health.current == 90 and shot.spent, "dash immunity consumes snowball without damage")
	players[0].health.invulnerable = false
	await process_frame
	shot = EnemySnowball.new()
	shot.party = arena.party
	shot.position = Vector2(0, -200)
	arena.get_node("Actors").add_child(shot)
	shot.set_physics_process(false)
	shot._physics_process(4.0)
	check(shot.spent, "missed snowball expires")
	ranged.state = RangedBehavior.State.WINDUP
	thrower.health.take_damage(DamageEvent.new(22, 2, Vector2(320, 0)))
	check(ranged.state == RangedBehavior.State.RECOVER, "cleaver interrupts thrower windup")
	# Check encounter composition and projectile cleanup between waves.
	charger.free()
	thrower.free()
	arena.encounter.wave = 2
	for index: int in range(4):
		arena.encounter._spawn_enemy()
	var has_charger: bool = false
	var has_ranged: bool = false
	for node: Node in get_nodes_in_group("enemies"):
		has_charger = has_charger or node.behavior is ChargeBehavior
		has_ranged = has_ranged or node.behavior is RangedBehavior
	check(has_charger and has_ranged, "wave two includes both enemy roles")
	shot = EnemySnowball.new()
	shot.party = arena.party
	arena.get_node("Actors").add_child(shot)
	for player: PenguinPlayer in players:
		player.health.take_damage(DamageEvent.new(1000))
	arena.encounter._physics_process(0.01)
	check(shot.spent and arena.encounter.state == EncounterDirector.State.FAILED, "party wipe cancels projectiles")
	arena.free()
	check(get_nodes_in_group("enemy_projectiles").is_empty(), "restart frees projectiles")
	print("ENEMY BEHAVIOR TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
