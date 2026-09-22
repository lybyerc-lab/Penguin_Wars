extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func fixture(number: int, mobile: bool = false) -> Node:
	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	arena.mobile_preview = mobile
	root.add_child(arena)
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	arena.journey.cave_number = number - 1
	arena.encounter.state = EncounterDirector.State.COMPLETE
	check(arena.journey.next_cave(), "fixture enters target cave")
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	return arena
func final_wave(arena: Node) -> ArenaBoss:
	arena.encounter.wave = arena.encounter.definition.wave_count
	arena.encounter.state = EncounterDirector.State.CLEARING
	arena.encounter.alive_count = 0
	arena.encounter._physics_process(0.1)
	var boss: ArenaBoss = arena.encounter.active_boss
	check(is_instance_valid(boss), "boss spawns after final normal wave")
	if boss != null:
		boss.set_physics_process(false)
	return boss
func defeat(arena: Node, boss: ArenaBoss) -> void:
	boss.health.take_damage(DamageEvent.new(1000000, 1))
	arena.encounter._physics_process(0.1)
func _run() -> void:
	for number: int in range(1, 61):
		var definition: BossDefinition = BossSchedule.for_cave(number)
		if number % 5 != 0:
			check(definition == null, "ordinary cave has no boss")
		else:
			var rank: int = 3 if number % 20 == 0 else (2 if number % 10 == 0 else 1)
			check(definition.rank == rank, "milestone precedence through endless cycle")
	check(is_equal_approx(BossSchedule.difficulty(21), 1.35) and is_equal_approx(BossSchedule.difficulty(41), 1.7), "endless difficulty rises each cycle")
	var arena: Node = fixture(5)
	var boss: ArenaBoss = final_wave(arena)
	check(boss.definition.rank == 1 and boss.health.maximum == 825, "mini-boss co-op HP scales with party")
	check(arena.encounter.state == EncounterDirector.State.BOSS and not arena.journey.can_leave(), "boss blocks cave exits")
	check(not arena.get_node("TravelHUD")._panel.visible and not arena.progression.shop_open(), "no premature victory/shop")
	var player: PenguinPlayer = arena.party.members()[0]
	var brain: BossBehavior = boss.behavior
	brain.remaining = 0
	brain.movement(boss, player, 0.01)
	check(brain.state == BossBehavior.State.WINDUP and not brain.contact_enabled(), "charge warning is harmless")
	var locked: Vector2 = brain.direction
	player.position += Vector2(0, 100)
	brain.movement(boss, player, 0.1)
	check(brain.direction == locked, "charge direction locked during warning")
	brain.on_damage(DamageEvent.new(1, 1, Vector2(400, 0)))
	check(brain.state == BossBehavior.State.WINDUP, "heavy hit cannot stun-lock boss")
	brain.movement(boss, player, 2)
	check(brain.contact_enabled(), "rush enables contact damage")
	brain.movement(boss, player, 2)
	check(not brain.contact_enabled(), "recovery disables contact damage")
	var before: int = arena.get_node("Wallet").balance(1)
	defeat(arena, boss)
	check(arena.encounter.state == EncounterDirector.State.COMPLETE, "boss defeat completes cave")
	check(arena.get_node("Wallet").balance(1) == before + 15, "mini-boss reward paid once")
	boss.health.take_damage(DamageEvent.new(10000))
	check(arena.get_node("Wallet").balance(1) == before + 15, "dead boss cannot duplicate rewards")
	arena.free()
	arena = fixture(10)
	boss = final_wave(arena)
	brain = boss.behavior
	player = arena.party.members()[0]
	brain.state = BossBehavior.State.WINDUP
	brain.attack = BossBehavior.Attack.VOLLEY
	brain.remaining = 0
	brain.movement(boss, player, 0.1)
	check(get_nodes_in_group("enemy_projectiles").size() == 8, "warden emits eight telegraphed shots")
	defeat(arena, boss)
	await process_frame
	check(get_nodes_in_group("enemy_projectiles").is_empty(), "boss victory clears shots")
	arena.free()
	arena = fixture(20, true)
	boss = final_wave(arena)
	brain = boss.behavior
	player = arena.party.members()[0]
	boss.health.current = boss.health.maximum * 0.4
	brain.state = BossBehavior.State.WINDUP
	brain.attack = BossBehavior.Attack.SLAM
	brain.remaining = 0
	player.position = boss.position + Vector2(50, 0)
	var hp: float = player.health.current
	brain.movement(boss, player, 0.1)
	check(brain.enraged and brain.shot_count() == 12 and player.health.current == hp - 28, "Mondo enrages and slam damages nearby players")
	player.health.invulnerable = true
	brain.state = BossBehavior.State.WINDUP
	brain.remaining = 0
	brain.movement(boss, player, 0.1)
	check(player.health.current == hp - 28, "dash immunity blocks slam")
	player.health.invulnerable = false
	defeat(arena, boss)
	check(arena.journey.war_choice_pending() and not paused, "mobile cave twenty offers campaign decision")
	check(not arena.journey.next_cave() and not arena.journey.return_to_town(), "ordinary exits cannot bypass decision")
	check(arena.get_node("TravelHUD")._town.text == "End the war", "ending choice shown")
	before = arena.get_node("Wallet").balance(1)
	arena.get_node("TravelHUD")._next.pressed.emit()
	check(arena.journey.endless and arena.journey.cave_number == 21, "endless button enters cave twenty-one")
	check(arena.get_node("Wallet").balance(1) == before and player.health.current == hp - 28, "endless retains run state")
	check(arena.encounter.definition.difficulty_multiplier == 1.35 and arena.encounter.definition.boss == null, "endless ordinary cave scales correctly")
	arena.free()
	arena = fixture(20)
	boss = final_wave(arena)
	defeat(arena, boss)
	arena.get_node("TravelHUD")._town.pressed.emit()
	check(arena.journey.war_ended and arena.journey.in_town and not arena.journey.next_cave(), "ending returns to peaceful town and closes expedition")
	check(arena.get_node("TravelHUD")._title.text == "THE WAR IS OVER!", "victory ending shown")
	arena.free()
	arena = fixture(40)
	arena.journey.endless = true
	boss = final_wave(arena)
	check(boss.definition.rank == 3 and boss.difficulty == 1.35, "endless repeats stronger Mondo")
	for penguin: PenguinPlayer in arena.party.members():
		penguin.health.take_damage(DamageEvent.new(10000))
	arena.encounter._physics_process(0.1)
	check(arena.encounter.state == EncounterDirector.State.FAILED and not arena.journey.can_leave(), "boss party wipe cannot clear cave")
	arena.free()
	print("BOSS CAMPAIGN TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
