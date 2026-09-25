extends SceneTree
## Real-renderer review captures for the Township V0.2 gameplay-feel pass.

const OUTPUT_DIR := "res://docs/reviews/township-v0-2"

func _initialize() -> void:
	call_deferred("_run")

func settle(frames: int = 18) -> void:
	for frame: int in range(frames):
		await process_frame

func park(players: Array[PenguinPlayer], center: Vector2) -> void:
	var offsets: Array[Vector2] = [Vector2(-48, -22), Vector2(48, -22), Vector2(-48, 32), Vector2(48, 32)]
	for index: int in range(players.size()):
		players[index].input_source.touch_movement = Vector2.ZERO
		players[index].position = center + offsets[index]

func shot(file_name: String) -> Error:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image().save_png("%s/%s" % [OUTPUT_DIR, file_name])

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	run.player_count = 4
	root.add_child(run)
	await settle(150)
	run.get_node("Overlay").visible = false
	run.get_node("HUD").visible = false
	var players: Array[PenguinPlayer] = run.party.members()
	var results: Array[Error] = []

	park(players, Vector2(0, 110))
	await settle(35)
	results.append(await shot("01-town-square-elevation.png"))
	park(players, Vector2(44, -345))
	await settle(35)
	results.append(await shot("02-great-hall-normal-camera.png"))
	park(players, Vector2(44, -470))
	await settle(35)
	results.append(await shot("03-great-hall-building-focus.png"))
	park(players, Vector2(-715, -95))
	await settle(35)
	results.append(await shot("04-workshop-entrance.png"))
	park(players, Vector2(475, -18))
	await settle(35)
	results.append(await shot("05-fish-market-approach.png"))
	park(players, TownshipV01.SLIDE_CENTER)
	await settle(28)
	# Re-center after the real slide physics moves the group while the eased
	# camera catches up, then allow the held-pose presentation to refresh.
	park(players, TownshipV01.SLIDE_CENTER)
	await settle(4)
	results.append(await shot("06-snow-slide-held-pose.png"))
	park(players, Vector2(230, 625))
	await settle(35)
	results.append(await shot("07-lodge-forecourt.png"))

	var failed: bool = results.any(func(result: Error) -> bool: return result != OK)
	print("TOWNSHIP V0.2 RENDER SMOKE: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
