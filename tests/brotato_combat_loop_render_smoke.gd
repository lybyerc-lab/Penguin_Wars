extends SceneTree
## Real-renderer proof for timed HUD rhythm and multi-weapon mount presence.
## Do not run with --headless.

const LANCE: WeaponDefinition = preload("res://resources/weapons/ice_lance.tres")
const CLEAVER: WeaponDefinition = preload("res://resources/weapons/fish_cleaver.tres")

func _initialize() -> void:
	call_deferred("_run")

func _capture(path: String) -> Error:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image().save_png(path)

func _freeze(player: PenguinPlayer) -> void:
	player.set_physics_process(false)
	for slot: int in range(player.weapon_rack.capacity()):
		var controller := player.weapon_rack.controller_at(slot)
		if controller != null:
			controller.set_physics_process(false)

func _run() -> void:
	var prototype := load("res://scenes/prototypes/evolution_checkpoint.tscn").instantiate() as Node2D
	root.add_child(prototype)
	for frame: int in range(24):
		await process_frame
	var player: PenguinPlayer = prototype.party.members()[0]
	var wave_timer: Error = await _capture("res://docs/brotato-wave-timer.png")
	_freeze(player)
	var four: Error = await _capture("res://docs/multi-weapon-four.png")
	var six_loadout: Array[WeaponDefinition] = [LANCE, LANCE, LANCE, CLEAVER, CLEAVER, CLEAVER]
	player.configure_weapon_loadout(six_loadout)
	for frame: int in range(3):
		await process_frame
	_freeze(player)
	var six: Error = await _capture("res://docs/multi-weapon-six.png")
	var four_loadout: Array[WeaponDefinition] = [LANCE, LANCE, CLEAVER, CLEAVER]
	player.configure_weapon_loadout(four_loadout)
	prototype.encounter.wave_cleared.emit(5)
	prototype.encounter.wave = 5
	prototype.encounter.state = EncounterDirector.State.INTERMISSION
	prototype.encounter._physics_process(prototype.encounter.definition.intermission_duration + 0.1)
	for frame: int in range(3):
		await process_frame
	var evolved: WeaponRack = player.weapon_rack
	var valid_evolved: bool = prototype.encounter.wave == 6 and evolved.weapon_at(0).tier == 2 and evolved.is_slot_empty(1) and evolved.weapon_at(2).tier == 2 and evolved.is_slot_empty(3)
	var wave_six: Error = await _capture("res://docs/evolution-wave-six.png")
	print("BROTATO COMBAT LOOP RENDER: ", "PASS" if wave_timer == OK and four == OK and six == OK and wave_six == OK and valid_evolved else "FAIL")
	quit(0 if wave_timer == OK and four == OK and six == OK and wave_six == OK and valid_evolved else 1)
