extends SceneTree
## Comprehensive regression suite for bosses, encounter escalation, telegraphs, and scaling.
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
			if node is BossActor:
				continue
			(node as ArenaEnemy).health.take_damage(DamageEvent.new(1000, 1))
		await process_frame
		if director.state in [EncounterDirector.State.BOSS, EncounterDirector.State.COMPLETE]:
			break
	director.auto_advance = false

func _run() -> void:
	# =========================================================================
	# 1. Milestone Boss Selection & Precedence (Twenty Waves Schedule)
	# =========================================================================
	var mini: BossDefinition = load("res://resources/bosses/mini.tres")
	var warden: BossDefinition = load("res://resources/bosses/warden.tres")
	var mondo: BossDefinition = load("res://resources/bosses/mondo.tres")
	check(mini.rank == 1 and warden.rank == 2 and mondo.rank == 3, "three boss ranks are defined")
	check(mini.maximum_health < warden.maximum_health and warden.maximum_health < mondo.maximum_health, "boss ranks escalate")
	check(mini.hit_radius > 0 and warden.hit_radius > 0 and mondo.hit_radius > 0, "bosses define hit_radius")

	var schedule: BossSchedule = load("res://resources/schedules/twenty_waves.tres")
	check(schedule != null and schedule.problems().is_empty(), "twenty_waves boss schedule has no problems")
	check(schedule.boss_for(1) == null, "wave 1 has no milestone boss")
	check(schedule.boss_for(4) == null, "wave 4 has no milestone boss")
	check(schedule.boss_for(5) == mini, "wave 5 selects Frostbreaker mini-boss")
	check(schedule.boss_for(10) == warden, "wave 10 selects Glacier Warden")
	check(schedule.boss_for(15) == mini, "wave 15 selects Frostbreaker mini-boss via exact tier")
	check(schedule.boss_for(20) == mondo, "wave 20 selects Mondo, the War King")
	# Endless intervals continue
	check(schedule.boss_for(25) == mini, "wave 25 repeats Frostbreaker")
	check(schedule.boss_for(30) == warden, "wave 30 repeats Glacier Warden")
	check(schedule.boss_for(35) == mini, "wave 35 repeats Frostbreaker")
	check(schedule.boss_for(40) == mondo, "wave 40 repeats Mondo")

	# =========================================================================
	# 2. 1-4 Player Party-Size HP Scaling Formula
	# =========================================================================
	# Base 500, party_health_scaling 0.65
	check(is_equal_approx(mini.scaled_health(1), 500.0), "1 player boss health is base 500")
	check(is_equal_approx(mini.scaled_health(2), 825.0), "2 player boss health is 1.65x (825)")
	check(is_equal_approx(mini.scaled_health(3), 1150.0), "3 player boss health is 2.30x (1150)")
	check(is_equal_approx(mini.scaled_health(4), 1475.0), "4 player boss health is 2.95x (1475)")

	# =========================================================================
	# 3. In-Game Expedition Walk: Spawn After Normal Waves & Gating
	# =========================================================================
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	root.add_child(run)
	await process_frame
	var party: PartyRoster = run.party
	var wallet: RunWallet = run.get_node("Wallet")

	# Walk to final cave room (black_ledge)
	travel(run, run.gates()[0])
	await process_frame
	await clear_waves(run)
	travel(run, run.gates()[0])
	await process_frame
	travel(run, run.gates()[0])
	await process_frame
	check(run.room.id == &"black_ledge", "reached final cave room black_ledge")
	check(run.encounter.definition.boss == mini, "black_ledge encounter brings Frostbreaker boss")
	check(run.encounter.active_boss == null, "boss does not spawn before waves finish")

	# Clear regular waves in black_ledge
	await clear_waves(run)

	# =========================================================================
	# 4. Boss Phase Entry & Room Exits Locked
	# =========================================================================
	check(run.encounter.state == EncounterDirector.State.BOSS, "encounter enters State.BOSS after normal waves")
	var boss: ArenaBoss = run.encounter.active_boss as ArenaBoss
	check(is_instance_valid(boss), "an ArenaBoss is spawned and active")
	check(boss is BossActor, "ArenaBoss conforms to BossActor interface")
	check(is_equal_approx(boss.health.maximum, 825.0), "2-player scaled health applied by configure()")
	for gate: PartyGate in run.gates():
		check(gate.locked, "room exits remain locked during boss phase")
	check(not run.progression.shop_open(), "shop does not open during active boss fight")

	# =========================================================================
	# 5. Knockback & Stun Resistance
	# =========================================================================
	check(boss.knockback_multiplier < 0.2, "boss has heavy knockback resistance (< 0.2)")

	# =========================================================================
	# 6. Telegraph Timing & Direction Locking
	# =========================================================================
	var player: PenguinPlayer = party.members()[0]
	boss.set_physics_process(false)
	var brain := boss.behavior as BossBehavior
	check(brain != null, "boss carries BossBehavior")

	brain.state = BossBehavior.State.STALK
	brain.remaining = 0.0
	brain.movement(boss, player, 0.01)
	check(brain.state == BossBehavior.State.WINDUP, "boss winds up before attacking")
	check(is_equal_approx(brain.remaining, 1.1), "standard telegraph windup is 1.1s")
	check(not brain.contact_enabled(), "boss contact damage is disabled during telegraph warning")

	var locked_dir: Vector2 = brain.direction
	player.position += Vector2(0, 150)
	brain.movement(boss, player, 0.1)
	check(brain.direction == locked_dir, "telegraph direction stays locked while player moves")

	brain.on_damage(DamageEvent.new(500, 1, Vector2(1000, 0)))
	check(brain.state == BossBehavior.State.WINDUP, "heavy damage does not cancel telegraph windup")

	# =========================================================================
	# 7. Rush Contact Windows
	# =========================================================================
	brain.movement(boss, player, 2.0)
	check(brain.state == BossBehavior.State.RUSH, "advances to RUSH attack")
	check(brain.contact_enabled(), "contact damage enabled during rush")

	brain.movement(boss, player, 2.0)
	check(brain.state == BossBehavior.State.RECOVER, "advances to RECOVER after rush")
	check(not brain.contact_enabled(), "contact damage disabled during recovery")

	# =========================================================================
	# 8. Mondo Enrage (Rank 3 below 50% HP)
	# =========================================================================
	boss.boss_definition = mondo
	boss.health.current = boss.health.maximum * 0.4
	brain.state = BossBehavior.State.STALK
	brain.remaining = 0.0
	brain.movement(boss, player, 0.01)
	check(brain.enraged, "Mondo enrages when health drops below 50%")
	check(is_equal_approx(brain.remaining, 0.8), "enraged telegraph windup is shortened to 0.8s")
	check(boss.phase() == "ENRAGED", "BossActor.phase() reports ENRAGED")

	# =========================================================================
	# 9. Dash Immunity Interactions
	# =========================================================================
	var hp_before_dash: float = player.health.current
	player.dash.tick(0.01, Vector2.RIGHT, true, true)
	check(player.dash.is_active(), "player is actively dashing")
	player.health.invulnerable = player.dash.is_active()
	# Apply boss attack damage while player is dashing
	player.health.take_damage(DamageEvent.new(boss.contact_damage))
	check(is_equal_approx(player.health.current, hp_before_dash), "dashing player takes zero damage from boss attack")
	player.dash.remaining = 0.0
	player.health.invulnerable = false

	# =========================================================================
	# 10. Projectile Room Bounds
	# =========================================================================
	brain._fire_volley(boss)
	var shots: Array[Node] = get_nodes_in_group("enemy_projectiles")
	check(shots.size() > 0, "boss volley spawned enemy projectiles")
	var sample_shot: EnemySnowball = shots[0] as EnemySnowball
	check(sample_shot != null, "projectile is EnemySnowball")
	check(sample_shot.room_bounds == boss.room_bounds, "projectile inherits room_bounds from boss")

	# =========================================================================
	# 11. Projectile Cleanup
	# =========================================================================
	run.encounter._clear_projectiles()
	await process_frame
	shots = get_nodes_in_group("enemy_projectiles")
	check(shots.is_empty(), "encounter projectile cleanup purges all active snowballs")

	# =========================================================================
	# 12. Boss Completion Gating & Reward Duplication Prevention
	# =========================================================================
	var p1_wallet: int = wallet.balance(1)
	var p2_wallet: int = wallet.balance(2)
	# Kill the boss
	boss.health.take_damage(DamageEvent.new(1000000, 1))
	run.encounter._physics_process(0.1)
	check(run.encounter.state == EncounterDirector.State.COMPLETE, "defeating boss transitions encounter to COMPLETE")
	check(run.encounter.active_boss == null, "active boss is cleared upon defeat")
	check(wallet.balance(1) == p1_wallet + mini.reward, "boss reward paid to player 1")
	check(wallet.balance(2) == p2_wallet + mini.reward, "boss reward paid to player 2")

	# Ensure reward duplication prevention
	boss.health.take_damage(DamageEvent.new(1000, 1))
	check(wallet.balance(1) == p1_wallet + mini.reward, "dead boss cannot pay reward twice")
	for gate: PartyGate in run.gates():
		check(not gate.locked, "gates unlock once boss is defeated (completion gating)")
	check(run.progression.shop_open(), "shop opens after room completion")

	# =========================================================================
	# 13. Party Wipe Behavior
	# =========================================================================
	var wipe_director := EncounterDirector.new()
	wipe_director.party = party
	wipe_director.actor_root = run.get_node("Actors")
	var wipe_enc := EncounterDefinition.new()
	wipe_enc.boss = mini
	wipe_director.definition = wipe_enc
	run.add_child(wipe_director)
	wipe_director.actor_bounds = Rect2(-400, -200, 800, 400)
	wipe_director._begin_boss()
	check(wipe_director.state == EncounterDirector.State.BOSS, "wipe test boss is spawned")

	var wallet_before_wipe: int = wallet.balance(1)
	# Wipe living players
	for member: PenguinPlayer in party.members(true):
		member.health.take_damage(DamageEvent.new(999999))
	wipe_director._physics_process(0.1)
	check(wipe_director.state == EncounterDirector.State.FAILED, "party wipe during boss phase sets state to FAILED")
	check(wallet.balance(1) == wallet_before_wipe, "no boss reward paid when party wipes")
	wipe_director.queue_free()
	await process_frame

	run.free()
	check(get_nodes_in_group("enemies").is_empty(), "no enemies leaked after run free")
	print("BOSS TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
