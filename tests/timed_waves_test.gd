extends SceneTree
## Focused lifecycle proof for the opt-in timed Evolution Checkpoint encounter.

var failures: int = 0
const LANCE_I: WeaponDefinition = preload("res://resources/weapons/ice_lance.tres")
const LANCE_II: WeaponDefinition = preload("res://resources/weapons/ice_lance_ii.tres")

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _disable_player_combat(prototype: Node2D) -> void:
	for player: PenguinPlayer in prototype.party.members():
		player.set_physics_process(false)
		for slot: int in range(player.weapon_rack.capacity()):
			var controller := player.weapon_rack.controller_at(slot)
			if controller != null:
				controller.set_physics_process(false)

func _run() -> void:
	var prototype := load("res://scenes/prototypes/evolution_checkpoint.tscn").instantiate() as Node2D
	root.add_child(prototype)
	await process_frame
	_disable_player_combat(prototype)
	var director: EncounterDirector = prototype.encounter
	var definition: EncounterDefinition = director.definition
	check(definition.uses_timed_waves() and definition.pacing_mode == EncounterDefinition.PacingMode.TIMED, "checkpoint explicitly opts into timed pacing")
	var intended := PackedFloat32Array([20.0, 25.0, 30.0, 35.0, 40.0, 45.0])
	for wave_number: int in range(1, 7):
		check(is_equal_approx(definition.duration_for_wave(wave_number), intended[wave_number - 1]), "wave %d has its authored timed duration" % wave_number)
	check(is_equal_approx(director.wave_duration(), 20.0) and director.wave_time_remaining() <= 20.0 and director.wave_time_remaining() > 19.5 and director.wave_progress() < 0.05, "wave timer API begins at the authored 20-second duration")

	# Timed waves keep running when no enemies remain and replenish while time remains.
	director._physics_process(0.1)
	check(director.alive_count == 1 and director.state == EncounterDirector.State.SPAWNING, "timed wave starts deterministic continuous spawning")
	for enemy: Node in prototype.get_node("Actors").get_children():
		if enemy is ArenaEnemy:
			enemy.queue_free()
	director.alive_count = 0
	director._physics_process(1.0)
	check(director.state == EncounterDirector.State.SPAWNING and director.wave_time_remaining() < 20.0, "zero living enemies never completes a timed wave early")
	director._physics_process(1.0)
	check(director.alive_count > 0 and director.alive_count <= director.timed_alive_cap(), "spawning replenishes under the encounter-owned alive cap")

	var cleared := [0]
	var loot := [0]
	director.wave_cleared.connect(func(_wave: int) -> void: cleared[0] += 1)
	director.loot_available.connect(func(_location: Vector2) -> void: loot[0] += 1)
	var projectile := EnemySnowball.new()
	prototype.get_node("Actors").add_child(projectile)
	director._physics_process(director.wave_time_remaining() + 0.1)
	check(cleared[0] == 1 and director.state == EncounterDirector.State.INTERMISSION and is_equal_approx(director.wave_time_remaining(), 0.0), "timer expiration emits normal completion once and enters automatic intermission")
	await process_frame
	check(director.alive_count == 0 and loot[0] == 0 and not is_instance_valid(projectile), "timer cleanup removes living enemies and projectiles without reward signals")
	prototype.progression.toggle_ready(1)
	check(director.wave == 1, "ready input cannot skip a timed intermission")
	director._physics_process(definition.intermission_duration + 0.1)
	check(director.wave == 2 and director.state == EncounterDirector.State.SPAWNING and is_equal_approx(director.wave_duration(), 25.0), "next timed wave begins automatically with its own duration")

	# Drive timer-only completion through wave five; the existing checkpoint
	# subscriber resolves its normal inventory-owned maturation operation once.
	while director.wave <= 5:
		director._physics_process(director.wave_time_remaining() + 0.1)
		director._physics_process(definition.intermission_duration + 0.1)
	check(prototype.checkpoint_resolved() and prototype.last_changes().size() == 2, "wave-five timer expiration triggers the checkpoint once")
	check(prototype.party.members()[0].weapon_rack.weapon_at(0) == LANCE_II, "wave-five timer maturity upgrades the rack")
	director._physics_process(definition.intermission_duration + 0.1)
	check(director.wave == 6 and is_equal_approx(director.wave_duration(), 45.0), "wave six starts automatically with the matured loadout and 45-second timer")
	prototype.free()
	await process_frame

	# Legacy arena and expedition definitions retain clear-all pacing; party wipe
	# remains a director failure in the timed prototype.
	var arena := load("res://scenes/arena/test_arena.tscn").instantiate() as Node2D
	root.add_child(arena)
	await process_frame
	check(not arena.encounter.uses_timed_waves(), "normal arena remains legacy clear-all pacing")
	arena.free()
	var expedition := load("res://scenes/run/expedition.tscn").instantiate() as Node2D
	root.add_child(expedition)
	await process_frame
	check(not expedition.encounter.uses_timed_waves(), "expedition remains legacy clear-all pacing")
	expedition.free()
	await process_frame
	prototype = load("res://scenes/prototypes/evolution_checkpoint.tscn").instantiate() as Node2D
	root.add_child(prototype)
	await process_frame
	prototype.party.members()[0].health.take_damage(DamageEvent.new(1000.0))
	prototype.encounter._physics_process(0.1)
	check(prototype.encounter.state == EncounterDirector.State.FAILED, "timed encounter still fails when every player is downed")
	prototype.free()

	print("TIMED WAVES TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
