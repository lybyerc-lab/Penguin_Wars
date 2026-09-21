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
	var wallet: RunWallet = arena.get_node("Wallet")
	var loot: ArenaLoot = arena.get_node("Loot")
	var builder: CastleBuilder = arena.get_node("Builder")
	var progression: RunProgression = arena.progression
	check(get_nodes_in_group("breakables").size() == 2, "two snowmen supplied at run start")
	var snowman: SupplySnowman = get_nodes_in_group("breakables")[0]
	players[0].position = snowman.position + Vector2(70, 0)
	players[0].weapon._physics_process(1.0)
	players[0].weapon._physics_process(1.0)
	check(not snowman.health.is_alive(), "weapon breaks snowman without enemy present")
	var health_pickup: RunPickup
	var currency: RunPickup
	for node: Node in arena.get_node("Actors").get_children():
		if node is RunPickup:
			if node.kind == RunPickup.Kind.HEALTH:
				health_pickup = node
			else:
				currency = node
	check(health_pickup != null and currency != null, "snowman drops health and snowflakes")
	check(not health_pickup.collect(players[0]), "full-health player cannot waste healing")
	players[0].health.take_damage(DamageEvent.new(10))
	check(health_pickup.collect(players[0]) and players[0].health.current == 100, "healing respects maximum health")
	check(not health_pickup.collect(players[1]), "pickup cannot be collected twice")
	check(currency.collect(players[0]), "snowflakes collect")
	check(wallet.balance(1) == 2 and wallet.balance(2) == 1, "shared drops split fairly into personal balances")
	check(players[0].experience.xp == 2 and players[1].experience.xp == 1, "snowflakes also grant XP")
	var stats := PlayerStats.new()
	stats.harvest_multiplier = 1.25
	var payout: int = 0
	for unit: int in range(4):
		payout += stats.harvest_yield(1)
	check(payout == 5, "fractional harvest bonus preserved on small pickups")
	check(not progression.choose(1, 0), "shopping blocked during combat")
	arena.encounter.state = EncounterDirector.State.INTERMISSION
	check(not progression.choose(1, 0), "insufficient funds cannot buy upgrade")
	wallet.credit(1, 10)
	var before: int = wallet.balance(1)
	check(progression.choose(1, 0) and wallet.balance(1) == before - 6, "purchase charges personal wallet once")
	check(players[0].weapon.damage_bonus == 3 and players[1].weapon.damage_bonus == 0, "purchased upgrade applies only to recipient")
	check(progression.price(1, 0) == 9 and progression.price(2, 0) == 6, "prices scale per player's purchases")
	progression.pending[1] = 1
	before = wallet.balance(1)
	check(progression.choose(1, 2) and wallet.balance(1) == before, "level-up choice stays free")
	check(players[0].stats.harvest_multiplier == 1.25 and players[1].stats.harvest_multiplier == 1.0, "harvesting multiplier is a personal upgrade")
	loot.spawn_pickup(Vector2(400, 200), RunPickup.Kind.SNOWFLAKE, 4)
	loot.bank_uncollected(1)
	check(progression.reserve == 4, "uncollected materials bank for next wave")
	progression.collect_materials(1, 2)
	check(progression.reserve == 2, "new pickup releases an equal reserve amount")
	before = wallet.balance(2)
	progression.finish_wave(1)
	progression.finish_wave(1)
	check(wallet.balance(2) == before + 5, "wave harvest pays exactly once")
	progression.toggle_ready(1)
	check(arena.encounter.state == EncounterDirector.State.INTERMISSION, "one ready player cannot end co-op shop")
	progression.toggle_ready(2)
	check(arena.encounter.state == EncounterDirector.State.SPAWNING and arena.encounter.wave == 2, "all living players ready starts next wave")
	players[0].position = Vector2.ZERO
	players[0].dash.facing = Vector2.RIGHT
	wallet.credit(1, 30)
	before = wallet.balance(1)
	check(builder.build(1) and wallet.balance(1) == before - 10, "player builds castle for ten snowflakes")
	check(not builder.build(1) and wallet.balance(1) == before - 10, "one castle per player; rejected build does not spend")
	players[1].position = Vector2.ZERO
	players[1].dash.facing = Vector2.RIGHT
	wallet.credit(2, 20)
	var other_before: int = wallet.balance(2)
	check(not builder.build(2) and wallet.balance(2) == other_before, "overlapping placement rejected without spending")
	check(not wallet.try_spend(2, -5) and wallet.balance(2) == other_before, "negative purchases cannot create currency")
	var castle: SnowCastle = builder.castles[1]
	castle.set_physics_process(false)
	var enemy: ArenaEnemy = load("res://scenes/actors/enemy.tscn").instantiate()
	enemy.party = arena.party
	enemy.position = castle.position + Vector2(100, 0)
	arena.get_node("Actors").add_child(enemy)
	enemy.set_physics_process(false)
	players[1].position = castle.position + Vector2(60, 0)
	var damage_sources: Array[int] = []
	enemy.health.damaged.connect(func(event: DamageEvent) -> void: damage_sources.append(event.source_player_id))
	castle._physics_process(1.0)
	var shot: CastleSnowball
	for node: Node in arena.get_node("Actors").get_children():
		if node is CastleSnowball:
			shot = node
	check(shot != null, "castle fires at enemy in range")
	shot.set_physics_process(false)
	shot._physics_process(0.5)
	shot._physics_process(0.5)
	check(enemy.health.current == 20 and players[1].health.current == 100, "castle projectile hits enemy once without friendly fire")
	check(damage_sources == [1], "castle damage preserves builder identity")
	arena.free()
	arena = load("res://scenes/arena/test_arena.tscn").instantiate()
	root.add_child(arena)
	check(arena.get_node("Wallet").balance(1) == 0 and arena.get_node("Builder").castles.is_empty(), "restart resets economy and defenses")
	check(arena.party.members()[0].stats.harvest_multiplier == 1.0, "restart resets harvesting")
	arena.free()
	print("ECONOMY TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
