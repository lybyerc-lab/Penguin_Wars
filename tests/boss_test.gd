extends SceneTree
## Boss phase, telegraphs and room difficulty, against the real cave.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func travel(run: Node2D, gate: PartyGate) -> void:
	for player: PenguinPlayer in run.party.members(true):
		player.position = gate.position
	gate._physics_process(PartyGate.DWELL + 0.2)

## Clears ordinary waves only, so the boss is left standing.
func clear_waves(run: Node2D) -> void:
	var director: EncounterDirector = run.encounter
	director.auto_advance = true
	for step: int in range(200):
		director._physics_process(10.0)
		for node: Node in get_nodes_in_group("enemies"):
			if node is ArenaBoss:
				continue
			(node as ArenaEnemy).health.take_damage(DamageEvent.new(1000, 1))
		await process_frame
		if director.state in [EncounterDirector.State.BOSS, EncounterDirector.State.COMPLETE]:
			break
	director.auto_advance = false

func _run() -> void:
	# --- data ------------------------------------------------------------
	var mini: BossDefinition = load("res://resources/bosses/mini.tres")
	var warden: BossDefinition = load("res://resources/bosses/warden.tres")
	var mondo: BossDefinition = load("res://resources/bosses/mondo.tres")
	check(mini.rank == 1 and warden.rank == 2 and mondo.rank == 3, "three boss ranks are defined")
	check(mini.maximum_health < warden.maximum_health and warden.maximum_health < mondo.maximum_health, "boss ranks escalate")
	var ledge: EncounterDefinition = load("res://resources/encounters/black_ledge.tres")
	var gallery: EncounterDefinition = load("res://resources/encounters/cracked_gallery.tres")
	var mouth: EncounterDefinition = load("res://resources/encounters/shelf_mouth.tres")
	check(ledge.boss == mini, "the cave's final room ends in the mini-boss")
	check(mouth.boss == null, "ordinary rooms have no boss")
	check(gallery.difficulty_multiplier > 1.0, "the loud branch is the harder one")

	# --- difficulty scales spawned enemies -------------------------------
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	root.add_child(run)
	await process_frame
	var party: PartyRoster = run.party
	var wallet: RunWallet = run.get_node("Wallet")
	var probe := EncounterDirector.new()
	probe.party = party
	probe.actor_root = run.get_node("Actors")
	probe.definition = gallery
	run.add_child(probe)
	probe._spawn_enemy()
	var scaled: ArenaEnemy = null
	for node: Node in run.get_node("Actors").get_children():
		if node is ArenaEnemy:
			scaled = node
	check(scaled != null, "the probe spawned an enemy")
	check(is_equal_approx(scaled.health.maximum, 28.0 * gallery.difficulty_multiplier), "difficulty scales enemy health")
	check(is_equal_approx(scaled.contact_damage, 8.0 * gallery.difficulty_multiplier), "difficulty scales contact damage")
	check(is_equal_approx(scaled.health.current, scaled.health.maximum), "a scaled enemy starts at full health")
	scaled.queue_free()
	probe.queue_free()
	await process_frame

	# --- a shooter's own damage reaches its snowball ----------------------
	var thrower: ArenaEnemy = load("res://scenes/actors/snowball_thrower.tscn").instantiate()
	thrower.party = party
	thrower.projectile_damage = 33.0
	run.get_node("Actors").add_child(thrower)
	thrower.set_physics_process(false)
	var aim: PenguinPlayer = party.members()[0]
	aim.position = Vector2(250, 0)
	thrower.position = Vector2.ZERO
	var ranged := thrower.behavior as RangedBehavior
	ranged.movement(thrower, aim, 1.0)
	ranged.movement(thrower, aim, 1.0)
	var shot: EnemySnowball = null
	for node: Node in get_nodes_in_group("enemy_projectiles"):
		shot = node as EnemySnowball
	check(shot != null, "the thrower fired")
	check(shot != null and is_equal_approx(shot.damage, 33.0), "a shooter's own damage reaches its snowball")
	check(is_equal_approx(thrower.hit_radius, 21.0), "an ordinary enemy keeps the original hit radius")
	if shot != null:
		shot.queue_free()
	thrower.queue_free()
	await process_frame

	# --- walk to the final room ------------------------------------------
	travel(run, run.gates()[0])
	await process_frame
	await clear_waves(run)
	travel(run, run.gates()[0])
	await process_frame
	check(run.room.id == &"glitter_seam", "reached the supply seam")
	travel(run, run.gates()[0])
	await process_frame
	check(run.room.id == &"black_ledge", "reached the final room")
	check(run.encounter.definition.boss == mini, "the room brought its boss along")
	check(run.encounter.active_boss == null, "no boss before the waves are done")
	await clear_waves(run)

	# --- the boss phase ---------------------------------------------------
	check(run.encounter.state == EncounterDirector.State.BOSS, "the boss follows the final wave")
	var boss: ArenaBoss = run.encounter.active_boss
	check(is_instance_valid(boss), "a boss is standing")
	check(boss.is_in_group("enemies"), "the boss is an ordinary target")
	# Two penguins: 500 * 1.0 * (1 + 0.65) = 825.
	check(is_equal_approx(boss.health.maximum, 825.0), "boss health scales with party size")
	check(boss.knockback_multiplier < 0.2, "the boss resists knockback")
	check(boss.hit_radius > 21.0 and boss.contact_radius > boss.hit_radius, "the boss is a larger target than a seal")
	for gate: PartyGate in run.gates():
		check(gate.locked, "the way home stays shut while the boss lives")
	check(not run.progression.shop_open(), "the boss fight is not a shopping phase")

	# --- telegraphs -------------------------------------------------------
	var player: PenguinPlayer = party.members()[0]
	boss.set_physics_process(false)
	var brain := boss.behavior as BossBehavior
	check(brain != null, "the boss carries a boss behavior")
	brain.remaining = 0.0
	brain.movement(boss, player, 0.01)
	check(brain.state == BossBehavior.State.WINDUP, "the boss winds up before attacking")
	check(not brain.contact_enabled(), "the warning itself is harmless")
	var locked: Vector2 = brain.direction
	player.position += Vector2(0, 140)
	brain.movement(boss, player, 0.1)
	check(brain.direction == locked, "the charge direction locks during the warning")
	brain.on_damage(DamageEvent.new(1, 1, Vector2(600, 0)))
	check(brain.state == BossBehavior.State.WINDUP, "a heavy hit cannot cancel the warning")
	brain.movement(boss, player, 2.0)
	check(brain.contact_enabled(), "the rush itself lands contact damage")
	brain.movement(boss, player, 2.0)
	check(not brain.contact_enabled(), "recovery is a safe window")
	check(brain.shot_count() > 0 and not brain.enraged, "a rank one boss does not enrage")

	# --- defeat and reward -------------------------------------------------
	var before: int = wallet.balance(1)
	var partner_before: int = wallet.balance(2)
	boss.health.take_damage(DamageEvent.new(1000000, 1))
	run.encounter._physics_process(0.1)
	check(run.encounter.state == EncounterDirector.State.COMPLETE, "defeating the boss clears the room")
	check(run.encounter.active_boss == null, "the defeated boss is released")
	check(wallet.balance(1) == before + mini.reward, "the boss reward is paid")
	check(wallet.balance(2) == partner_before + mini.reward, "every living penguin is paid")
	boss.health.take_damage(DamageEvent.new(1000, 1))
	check(wallet.balance(1) == before + mini.reward, "a dead boss cannot pay twice")
	for gate: PartyGate in run.gates():
		check(not gate.locked, "the way home opens once the boss is down")
	check(run.progression.shop_open(), "the room's shop opens after the boss")

	run.free()
	check(get_nodes_in_group("enemies").is_empty(), "no boss leaks when the run ends")
	print("BOSS TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
