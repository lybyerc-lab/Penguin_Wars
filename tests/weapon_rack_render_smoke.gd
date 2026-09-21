extends SceneTree
## Live renderer proof for the ordinary two-player rack and an injected second
## weapon. Do not run with --headless.

const CLEAVER: WeaponDefinition = preload("res://resources/weapons/fish_cleaver.tres")

func _initialize() -> void:
	call_deferred("_run")

func _capture(path: String) -> Error:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image().save_png(path)

func _run() -> void:
	var arena := load("res://scenes/arena/test_arena.tscn").instantiate() as Node2D
	root.add_child(arena)
	for frame: int in range(12):
		await process_frame
	var normal: Error = await _capture("res://docs/weapon-rack-standard.png")
	var players: Array[PenguinPlayer] = arena.party.members()
	for player: PenguinPlayer in players:
		player.set_physics_process(false)
		for slot: int in range(player.weapon_rack.capacity()):
			var controller := player.weapon_rack.controller_at(slot)
			if controller != null:
				controller.set_physics_process(false)
	players[0].weapon_rack.add_weapon(CLEAVER)
	# Aim both owned controllers into a readable spread so the capture makes the
	# second held weapon obvious without changing normal gameplay behavior.
	players[0].weapon_rack.controller_at(0).aim_angle = -0.55
	players[0].weapon_rack.controller_at(1).aim_angle = 0.65
	for frame: int in range(3):
		await process_frame
	var injected: Error = await _capture("res://docs/weapon-rack-two-weapons.png")
	print("WEAPON RACK RENDER: ", "PASS" if normal == OK and injected == OK else "FAIL")
	quit(0 if normal == OK and injected == OK else 1)
