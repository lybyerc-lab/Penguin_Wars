extends SceneTree
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var wide: bool = "--wide" in OS.get_cmdline_user_args()
	if wide:
		root.size = Vector2i(1600, 720)
	var suffix: String = "-wide" if wide else ""
	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	arena.mobile_preview = true
	root.add_child(arena)
	for frame: int in range(210):
		await process_frame
		if frame == 60:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/location-arrival%s.png" % suffix)
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png("res://docs/mobile-controls%s.png" % suffix)
	arena.encounter.set_physics_process(false)
	arena.encounter.state = EncounterDirector.State.INTERMISSION
	arena.get_node("MobileHUD").open_sheet()
	for frame: int in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var sheet_result: Error = root.get_texture().get_image().save_png("res://docs/mobile-character-sheet%s.png" % suffix)
	print("MOBILE RENDER: ", "PASS" if result == OK and sheet_result == OK else "FAIL")
	quit(0 if result == OK and sheet_result == OK else 1)
