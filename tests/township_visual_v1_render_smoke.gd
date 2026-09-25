extends SceneTree
## Real-renderer review set for the approved Township Visual V1 integration.

const OUTPUT_DIR := "res://docs/reviews/township-visual-v1"

func _initialize() -> void:
	call_deferred("_run")

func settle(frames: int = 28) -> void:
	for frame: int in range(frames):
		await process_frame

func park(players: Array[PenguinPlayer], center: Vector2) -> void:
	var offsets: Array[Vector2] = [Vector2(-46, -24), Vector2(46, -24), Vector2(-46, 30), Vector2(46, 30)]
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
	await settle(120)
	run.get_node("Overlay").visible = false
	run.get_node("HUD").visible = false
	var players: Array[PenguinPlayer] = run.party.members()
	var camera := run.get_node("Camera") as PartyCamera
	var results: Array[Error] = []

	park(players, Vector2(0, 90))
	await settle()
	results.append(await shot("01-town-square.png"))
	park(players, Vector2(44, -470))
	await settle(40)
	results.append(await shot("02-great-hall-focus.png"))
	park(players, Vector2(-715, -95))
	await settle(40)
	results.append(await shot("03-workshop.png"))
	park(players, Vector2(-644, 670))
	await settle(40)
	results.append(await shot("04-nurse-south-entrance.png"))
	park(players, Vector2(620, 80))
	await settle(40)
	results.append(await shot("05-fish-market-pond.png"))
	park(players, TownshipV01.SLIDE_CENTER)
	await settle(30)
	park(players, TownshipV01.SLIDE_CENTER)
	await settle(4)
	results.append(await shot("06-snow-slide.png"))
	park(players, Vector2(210, 790))
	await settle(40)
	results.append(await shot("07-lodge-bell-gate.png"))

	camera.process_mode = Node.PROCESS_MODE_DISABLED
	camera.position = Vector2(0, 200)
	camera.zoom = Vector2.ONE * 0.46
	await settle(8)
	results.append(await shot("08-whole-town-traversal.png"))
	camera.process_mode = Node.PROCESS_MODE_INHERIT

	players[0].position = Vector2(-235, -610)
	players[1].position = Vector2(-235, -505)
	players[2].position = Vector2(210, -610)
	players[3].position = Vector2(210, -505)
	await settle(35)
	results.append(await shot("09-hall-foreground-occlusion.png"))
	park(players, Vector2(0, 150))
	await settle(35)
	results.append(await shot("10-four-player-township.png"))

	var failed: bool = results.any(func(result: Error) -> bool: return result != OK)
	print("TOWNSHIP VISUAL V1 RENDER SMOKE: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
