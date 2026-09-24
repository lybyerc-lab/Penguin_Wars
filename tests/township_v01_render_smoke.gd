extends SceneTree
## Real-renderer engineering captures for the playable Township V0.1 blockout.

const OUTPUT_DIR := "res://docs/reviews/township-v0-1"

func _initialize() -> void:
	call_deferred("_run")

func settle(frames: int = 16) -> void:
	for frame: int in range(frames):
		await process_frame

func park(players: Array[PenguinPlayer], center: Vector2) -> void:
	var offsets: Array[Vector2] = [Vector2(-55, -25), Vector2(55, -25), Vector2(-55, 35), Vector2(55, 35)]
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
	# Review captures are for world scale and navigation. Service panels have
	# their own existing render fixture and obscure the landmark clearances.
	run.get_node("Overlay").visible = false
	var players: Array[PenguinPlayer] = run.party.members()
	var results: Array[Error] = []

	park(players, Vector2(0, 120))
	await settle(28)
	results.append(await shot("01-four-player-town-square.png"))
	park(players, Vector2(44, -470))
	await settle(28)
	results.append(await shot("02-great-hall.png"))
	park(players, Vector2(-875, 110))
	await settle(28)
	results.append(await shot("03-snow-slide.png"))
	park(players, Vector2(675, 35))
	await settle(28)
	results.append(await shot("04-fish-market.png"))
	park(players, Vector2(220, 610))
	await settle(28)
	results.append(await shot("05-south-forecourt.png"))
	players[0].position = Vector2(20, 850)
	players[1].position = Vector2(110, 850)
	players[2].position = Vector2(525, 1580)
	players[3].position = Vector2(615, 1580)
	run.get_node("HUD").visible = false
	await settle(28)
	results.append(await shot("06-departure-gate-route.png"))

	var failed: bool = results.any(func(result: Error) -> bool: return result != OK)
	print("TOWNSHIP V0.1 RENDER SMOKE: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
