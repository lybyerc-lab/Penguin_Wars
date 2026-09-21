extends SceneTree
## Uses the real renderer; do not run with --headless.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	root.add_child(arena)
	for frame: int in range(180):
		await process_frame
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png("res://docs/arena-preview.png")
	print("RENDER SMOKE: ", "PASS" if result == OK else "FAIL")
	quit(0 if result == OK else 1)
