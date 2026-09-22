extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("FAILED: " + message)
	else:
		print("  PASS: " + message)

func _run() -> void:
	print("Running Focused Snow Pickup Tests (A through R)...")

	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	root.add_child(arena)
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	await physics_frame

	var players: Array[PenguinPlayer] = arena.party.members()
	var wallet: RunWallet = arena.get_node("Wallet")
	var loot: ArenaLoot = arena.get_node("Loot")
	var progression: RunProgression = arena.progression

	# Park Player 1 out of the way for initial single-player tests
	players[1].global_position = Vector2(9999, 9999)

	# A. amount is never changed by visual tier
	var p_a := RunPickup.new()
	p_a.kind = RunPickup.Kind.SNOWFLAKE
	p_a.amount = 5
	var tier_a: RunPickup.ValueTier = p_a.value_tier()
	check(tier_a == RunPickup.ValueTier.CHUNKY and p_a.amount == 5, "A: amount is never changed by visual tier query")
	p_a.amount = 12
	var tier_a2: RunPickup.ValueTier = p_a.value_tier()
	check(tier_a2 == RunPickup.ValueTier.JACKPOT and p_a.amount == 12, "A: amount remains intact across multiple tier queries")
	p_a.free()

	# B. amount 1–2 resolves SMALL
	var p_b1 := RunPickup.new()
	p_b1.amount = 1
	var p_b2 := RunPickup.new()
	p_b2.amount = 2
	check(p_b1.value_tier() == RunPickup.ValueTier.SMALL and p_b2.value_tier() == RunPickup.ValueTier.SMALL, "B: amount 1-2 resolves SMALL")
	p_b1.free()
	p_b2.free()

	# C. amount 3–5 resolves CHUNKY
	var p_c3 := RunPickup.new()
	p_c3.amount = 3
	var p_c5 := RunPickup.new()
	p_c5.amount = 5
	check(p_c3.value_tier() == RunPickup.ValueTier.CHUNKY and p_c5.value_tier() == RunPickup.ValueTier.CHUNKY, "C: amount 3-5 resolves CHUNKY")
	p_c3.free()
	p_c5.free()

	# D. amount 6–9 resolves BIG
	var p_d6 := RunPickup.new()
	p_d6.amount = 6
	var p_d9 := RunPickup.new()
	p_d9.amount = 9
	check(p_d6.value_tier() == RunPickup.ValueTier.BIG and p_d9.value_tier() == RunPickup.ValueTier.BIG, "D: amount 6-9 resolves BIG")
	p_d6.free()
	p_d9.free()

	# E. amount 10+ resolves JACKPOT
	var p_e10 := RunPickup.new()
	p_e10.amount = 10
	var p_e50 := RunPickup.new()
	p_e50.amount = 50
	check(p_e10.value_tier() == RunPickup.ValueTier.JACKPOT and p_e50.value_tier() == RunPickup.ValueTier.JACKPOT, "E: amount 10+ resolves JACKPOT")
	p_e10.free()
	p_e50.free()

	# F. a fresh Snow pickup begins in arrival/landing state
	var p_f := RunPickup.new()
	p_f.kind = RunPickup.Kind.SNOWFLAKE
	check(not p_f.is_settled(), "F: a fresh Snow pickup begins in arrival/landing state")

	# G. pickup settles after its short landing sequence
	p_f._physics_process(RunPickup.LANDING_DURATION + 0.05)
	check(p_f.is_settled(), "G: pickup settles after its short landing sequence")
	p_f.free()

	# H. Snow outside magnet radius does not move toward the player
	players[0].global_position = Vector2(0, 0)
	var p_h: RunPickup = loot.spawn_pickup(Vector2(200, 0), RunPickup.Kind.SNOWFLAKE, 2)
	var initial_h_pos: Vector2 = p_h.global_position
	p_h._physics_process(RunPickup.LANDING_DURATION + 0.05)
	p_h._physics_process(0.1)
	check(not p_h.is_magnetized(), "H: Snow outside magnet radius is not magnetized")
	check(p_h.global_position == initial_h_pos, "H: Snow outside magnet radius does not move toward player")
	p_h.free()

	# I. Snow inside magnet radius begins suction
	var p_i: RunPickup = loot.spawn_pickup(Vector2(25, 0), RunPickup.Kind.SNOWFLAKE, 2)
	players[0].global_position = Vector2(0, 0)
	p_i._physics_process(0.05)
	check(p_i.is_magnetized(), "I: Snow inside magnet radius begins suction")
	check(p_i.global_position.distance_to(players[0].global_position) < 25.0, "I: suction moves pickup toward player")
	p_i.free()

	# J. suction moves toward the nearest eligible living player
	players[0].global_position = Vector2(20, 0)
	players[1].global_position = Vector2(-40, 0)
	var p_j: RunPickup = loot.spawn_pickup(Vector2(0, 0), RunPickup.Kind.SNOWFLAKE, 2)
	p_j._physics_process(0.04)
	check(p_j.is_magnetized() and p_j.global_position.x > 0.0, "J: suction moves toward nearest living player (Player 0)")
	p_j.free()

	# Dead player is skipped
	players[0].health.take_damage(DamageEvent.new(10000, 1))
	check(not players[0].health.is_alive(), "J prep: Player 0 is downed")
	players[1].global_position = Vector2(25, 0)
	var p_j2: RunPickup = loot.spawn_pickup(Vector2(0, 0), RunPickup.Kind.SNOWFLAKE, 2)
	p_j2._physics_process(0.04)
	check(p_j2.is_magnetized() and p_j2.global_position.x > 0.0, "J: suction targets living Player 1 when Player 0 is downed")
	p_j2.free()
	# Revive Player 0 and restore full health
	players[0].health.revive(100)
	check(players[0].health.is_alive(), "J post: Player 0 revived")

	# Move Player 1 away again for test K
	players[1].global_position = Vector2(9999, 9999)

	# K. pickup_bonus increases attraction reach
	players[0].global_position = Vector2(0, 0)
	players[0].stats.pickup_bonus = 0.0
	var p_k: RunPickup = loot.spawn_pickup(Vector2(45, 0), RunPickup.Kind.SNOWFLAKE, 2)
	check(p_k.magnet_radius_for(players[0]) == RunPickup.BASE_MAGNET_RADIUS, "K: base magnet reach matches BASE_MAGNET_RADIUS")
	p_k._physics_process(0.05)
	check(not p_k.is_magnetized(), "K: 45px distance is outside base reach (30px)")

	# Apply pickup_bonus +25
	players[0].stats.pickup_bonus = 25.0
	check(p_k.magnet_radius_for(players[0]) == 55.0, "K: pickup_bonus increases magnet radius to 55px")
	p_k._physics_process(0.05)
	check(p_k.is_magnetized(), "K: pickup becomes magnetized when in range with pickup_bonus")
	p_k.free()
	players[0].stats.pickup_bonus = 0.0

	# L. collection still emits the original amount exactly once
	var p_l := RunPickup.new()
	p_l.kind = RunPickup.Kind.SNOWFLAKE
	p_l.amount = 7
	var emissions: Array = []
	p_l.collected.connect(func(pid: int, amt: int): emissions.append([pid, amt]))
	var collected_l: bool = p_l.collect(players[0])
	check(collected_l, "L: collect returns true on success")
	check(emissions.size() == 1 and emissions[0][0] == players[0].identity.player_id and emissions[0][1] == 7, "L: collection emits exact original amount (7) once")

	# M. claimed pickup cannot be collected twice
	var collected_m2: bool = p_l.collect(players[0])
	check(not collected_m2, "M: claimed pickup cannot be collected twice")
	check(emissions.size() == 1, "M: no second collection signal emission")
	check(p_l.collection_fx_active(), "M: collection finishing effect is active")
	p_l.free()

	# N. wallet/XP allocation behavior remains owned outside RunPickup
	var p_n := RunPickup.new()
	p_n.kind = RunPickup.Kind.SNOWFLAKE
	p_n.amount = 5
	var start_bal_0: int = wallet.balance(1)
	p_n.collect(players[0])
	check(wallet.balance(1) == start_bal_0, "N: RunPickup does not directly mutate wallet; allocation is decoupled")
	p_n.free()

	# O. uncollected Snow can still be banked
	var p_o: RunPickup = loot.spawn_pickup(Vector2(300, 300), RunPickup.Kind.SNOWFLAKE, 6)
	var start_reserve: int = progression.reserve
	loot.bank_uncollected(1)
	check(progression.reserve == start_reserve + 6, "O: uncollected Snow increases progression reserve by pickup amount")
	check(p_o.claimed, "O: banked pickup is marked claimed")

	# P. health pickup behavior is not broken
	var p_p: RunPickup = loot.spawn_pickup(Vector2(-100, -100), RunPickup.Kind.HEALTH, 25)
	check(p_p.is_settled(), "P: health pickup is considered settled immediately")
	check(not p_p.collect(players[0]), "P: full-health player cannot collect healing")
	players[0].health.take_damage(DamageEvent.new(30, 1))
	check(p_p.collect(players[0]), "P: injured player can collect health pickup")
	check(players[0].health.current == 95, "P: health pickup heals the expected amount")

	# Q. 1–4 player setup remains valid
	var arena_4: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	arena_4.player_count = 4
	root.add_child(arena_4)
	for node: Node in arena_4.find_children("*", "", true, false):
		node.set_physics_process(false)
	await physics_frame
	check(arena_4.party.members().size() == 4, "Q: 4-player party initialized")
	var p_q: RunPickup = arena_4.get_node("Loot").spawn_pickup(arena_4.party.members()[3].global_position + Vector2(15, 0), RunPickup.Kind.SNOWFLAKE, 3)
	p_q._physics_process(0.05)
	check(p_q.is_magnetized(), "Q: pickup magnetizes to player 4 in 4-player party")
	arena_4.free()

	# R. no shared mutable visual state leaks between pickups
	var p_r1: RunPickup = loot.spawn_pickup(Vector2(0, 0), RunPickup.Kind.SNOWFLAKE, 2)
	var p_r2: RunPickup = loot.spawn_pickup(Vector2(100, 100), RunPickup.Kind.SNOWFLAKE, 8)
	check(p_r1.value_tier() == RunPickup.ValueTier.SMALL and p_r2.value_tier() == RunPickup.ValueTier.BIG, "R: independent value tiers")
	p_r1.collect(players[0])
	check(p_r1.claimed and not p_r2.claimed, "R: claiming one pickup does not affect another")
	check(p_r1.collection_fx_active() and not p_r2.collection_fx_active(), "R: collection FX does not leak between instances")
	p_r1.free()
	p_r2.free()

	arena.free()

	print("FOCUSED SNOW PICKUP TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
