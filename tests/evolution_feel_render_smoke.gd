extends SceneTree
## Combined real-renderer proof for CharacterVisual state plumbing, timed HUD, and rack mounts.
## Do not run with --headless.

const LANCE: WeaponDefinition = preload("res://resources/weapons/ice_lance.tres")
const CLEAVER: WeaponDefinition = preload("res://resources/weapons/fish_cleaver.tres")

func _initialize() -> void:
	call_deferred("_run")

func _capture(path: String) -> Error:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image().save_png(path)

func _freeze_combat(player: PenguinPlayer) -> void:
	player.set_physics_process(false)
	for slot: int in range(player.weapon_rack.capacity()):
		var controller := player.weapon_rack.controller_at(slot)
		if controller != null:
			controller.set_physics_process(false)

func _settle() -> void:
	for _frame: int in range(12):
		await process_frame

func _run() -> void:
	var prototype := load("res://scenes/prototypes/evolution_checkpoint.tscn").instantiate() as Node2D
	root.add_child(prototype)
	await _settle()
	var player: PenguinPlayer = prototype.party.members()[0]
	_freeze_combat(player)

	# Four distinct weapons and a running timed HUD from the integrated runtime.
	var four: Error = await _capture("res://docs/evolution-feel-four-weapons.png")

	# Six slots use the same player-centered combat geometry but visibly separate lanes.
	player.configure_weapon_loadout([LANCE, LANCE, LANCE, CLEAVER, CLEAVER, CLEAVER])
	await _settle()
	_freeze_combat(player)
	var six: Error = await _capture("res://docs/evolution-feel-six-weapons.png")

	# The approved dash pose remains untouched while the rack stays readable.
	player.dash.direction = Vector2.RIGHT
	player.dash.remaining = 0.14
	await _settle()
	var dash: Error = await _capture("res://docs/evolution-feel-dash.png")
	player.dash.remaining = 0.0

	# Restore the checkpoint loadout, resolve its normal wave-five event, and
	# capture wave six with the two surviving stable slots.
	player.configure_weapon_loadout([LANCE, LANCE, CLEAVER, CLEAVER])
	prototype.encounter.wave_cleared.emit(5)
	prototype.encounter.wave = 5
	prototype.encounter.state = EncounterDirector.State.INTERMISSION
	prototype.encounter._physics_process(prototype.encounter.definition.intermission_duration + 0.1)
	await _settle()
	var rack: WeaponRack = player.weapon_rack
	var evolved: bool = prototype.encounter.wave == 6 and rack.occupied_count() == 2 and rack.weapon_at(0).tier == 2 and rack.weapon_at(2).tier == 2 and rack.is_slot_empty(1) and rack.is_slot_empty(3)
	var wave_six: Error = await _capture("res://docs/evolution-feel-wave-six.png")
	prototype.free()
	await process_frame

	# Co-op keeps timed combat and HUD context alive while one player is KO'd.
	prototype = load("res://scenes/prototypes/evolution_checkpoint.tscn").instantiate() as Node2D
	prototype.player_count = 2
	root.add_child(prototype)
	await _settle()
	var downed: PenguinPlayer = prototype.party.members()[0]
	var partner: PenguinPlayer = prototype.party.members()[1]
	_freeze_combat(downed)
	_freeze_combat(partner)
	downed.health.take_damage(DamageEvent.new(1000.0))
	await _settle()
	var ko_clean: bool = not downed.health.is_alive() and prototype.encounter.state == EncounterDirector.State.SPAWNING and not downed.weapon_rack.controller_at(0).get_node("Visual").visible
	var downed_capture: Error = await _capture("res://docs/evolution-feel-downed.png")

	var all_ok: bool = four == OK and six == OK and dash == OK and wave_six == OK and downed_capture == OK and evolved and ko_clean
	print("EVOLUTION FEEL RENDER: ", "PASS" if all_ok else "FAIL")
	quit(0 if all_ok else 1)
