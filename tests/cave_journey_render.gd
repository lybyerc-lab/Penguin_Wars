extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	arena.mobile_preview = "--mobile" in OS.get_cmdline_user_args()
	root.add_child(arena)
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	for frame: int in range(210):
		await process_frame
	arena.encounter.wave = 3
	arena.encounter.state = EncounterDirector.State.COMPLETE
	arena.progression.finish_wave(3)
	arena.encounter.state_changed.emit()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var suffix: String = "-mobile" if arena.mobile_preview else ""
	var result: Error = root.get_texture().get_image().save_png("res://docs/cave-cleared%s.png" % suffix)
	arena.journey.return_to_town()
	for frame: int in range(210):
		await process_frame
	await RenderingServer.frame_post_draw
	result = result | root.get_texture().get_image().save_png("res://docs/town-camp%s.png" % suffix)
	print("JOURNEY RENDER: ", "PASS" if result == OK else "FAIL")
	quit(0 if result == OK else 1)
