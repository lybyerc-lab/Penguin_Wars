extends SceneTree
## Scripted real-gameplay review route for Township V0.2.

func _initialize() -> void:
	call_deferred("_run")

func wait_frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame

func drive(player: PenguinPlayer, direction: Vector2, frames: int, dash_first: bool = false) -> void:
	player.input_source.touch_movement = direction.normalized()
	if dash_first:
		player.input_source.touch_dash_pending = true
	await wait_frames(frames)
	player.input_source.touch_movement = Vector2.ZERO
	await wait_frames(18)

func _run() -> void:
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	run.player_count = 1
	root.add_child(run)
	await wait_frames(75)
	run.get_node("Overlay").visible = false
	var player: PenguinPlayer = run.party.members()[0]

	# Wider normal traversal, then a natural approach to the Hall pad.
	player.position = Vector2(44, -250)
	await wait_frames(35)
	await drive(player, Vector2.UP, 58)
	# Hold long enough to show the camera settle on the building.
	await wait_frames(70)
	await drive(player, Vector2.DOWN, 58)
	await wait_frames(45)

	# The slide keeps its physics but holds a clear sliding pose.
	player.position = TownshipV01.SLIDE_CENTER + Vector2(-15, -190)
	await wait_frames(20)
	await drive(player, Vector2.DOWN, 92)

	# Finish through the forecourt and Departure Gate.
	player.position = TownshipV01.DEPARTURE_GATE + Vector2(0, -190)
	await wait_frames(25)
	await drive(player, Vector2.DOWN, 125, true)
	await wait_frames(35)
	quit(0)
