extends SceneTree
## Real-renderer proof for a merged Tier II rack marker and class summary.
## Do not run with --headless.

const LANCE_I: WeaponDefinition = preload("res://resources/weapons/ice_lance.tres")

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
	var player: PenguinPlayer = arena.party.members()[0]
	player.set_physics_process(false)
	for slot: int in range(player.weapon_rack.capacity()):
		var controller := player.weapon_rack.controller_at(slot)
		if controller != null:
			controller.set_physics_process(false)
	player.weapon_rack.add_weapon(LANCE_I)
	if not player.weapon_rack.merge_slots(0, 1) or player.weapon_rack.weapon_at(0).tier != 2:
		push_error("Tier render setup did not create Ice Lance II")
		quit(1)
		return
	for frame: int in range(3):
		await process_frame
	var rack_capture: Error = await _capture("res://docs/weapon-tiers-rack.png")
	arena.get_node("HUD").call("open_sheet", player)
	for frame: int in range(3):
		await process_frame
	var sheet_capture: Error = await _capture("res://docs/weapon-tiers-sheet.png")
	print("WEAPON TIERS RENDER: ", "PASS" if rack_capture == OK and sheet_capture == OK else "FAIL")
	quit(0 if rack_capture == OK and sheet_capture == OK else 1)
