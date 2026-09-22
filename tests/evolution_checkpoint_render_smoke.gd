extends SceneTree
## Real-renderer proof for the dedicated evolution checkpoint scene.
## Do not run with --headless.

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
	for frame: int in range(12):
		await process_frame
	var player: PenguinPlayer = prototype.party.members()[0]
	_freeze(player)
	var before: Error = await _capture("res://docs/evolution-before.png")
	prototype.encounter.wave_cleared.emit(5)
	for frame: int in range(3):
		await process_frame
	var rack: WeaponRack = player.weapon_rack
	var valid_after: bool = prototype.checkpoint_resolved() and prototype.checkpoint_notice_visible() and rack.weapon_at(0).tier == 2 and rack.is_slot_empty(1) and rack.weapon_at(2).tier == 2 and rack.is_slot_empty(3)
	var after: Error = await _capture("res://docs/evolution-after.png")
	print("EVOLUTION CHECKPOINT RENDER: ", "PASS" if before == OK and after == OK and valid_after else "FAIL")
	quit(0 if before == OK and after == OK and valid_after else 1)
