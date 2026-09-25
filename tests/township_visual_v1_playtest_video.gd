extends SceneTree
## Short runtime tour of the integrated Township art and gameplay seams.

func _initialize() -> void:
	call_deferred("_run")

func wait_frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame

func place_pair(players: Array[PenguinPlayer], first: Vector2, second: Vector2, hold: int = 48) -> void:
	players[0].input_source.touch_movement = Vector2.ZERO
	players[1].input_source.touch_movement = Vector2.ZERO
	players[0].position = first
	players[1].position = second
	await wait_frames(hold)

func _run() -> void:
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	run.player_count = 2
	root.add_child(run)
	await wait_frames(75)
	run.get_node("Overlay").visible = false
	run.get_node("HUD").visible = false
	var players: Array[PenguinPlayer] = run.party.members()

	await place_pair(players, Vector2(-50, 80), Vector2(50, 80), 55)
	# P2 activates the first focus pad while P1 remains nearby and outside it.
	await place_pair(players, Vector2(189, -470), Vector2(44, -470), 75)
	await place_pair(players, Vector2(-660, -65), Vector2(-730, -95), 58)
	await place_pair(players, TownshipV01.SLIDE_CENTER + Vector2(-35, -40), TownshipV01.SLIDE_CENTER + Vector2(35, -40), 40)
	await place_pair(players, Vector2(-700, 670), Vector2(-644, 670), 58)
	await place_pair(players, Vector2(545, 25), Vector2(475, -18), 58)
	await place_pair(players, Vector2(170, 780), Vector2(250, 780), 58)
	await place_pair(players, TownshipV01.DEPARTURE_BOUNDARY + Vector2(-70, -90), TownshipV01.DEPARTURE_BOUNDARY + Vector2(20, -90), 42)
	quit(0)
