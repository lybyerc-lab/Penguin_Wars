extends SceneTree
## Scripted real-gameplay route used only to record the Township review video.
## Movement enters through LocalPlayerInput, so player physics, collisions,
## camera tracking, dash, Waddle playback, and the slide all run normally.

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
	await wait_frames(15)

func _run() -> void:
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	run.player_count = 1
	root.add_child(run)
	await wait_frames(75)
	run.get_node("Overlay").visible = false
	var player: PenguinPlayer = run.party.members()[0]

	# Spawn, idle, and walk north across the square toward the Great Hall.
	await wait_frames(30)
	await drive(player, Vector2.UP, 95)

	# Enter the physical slide and let its downhill shove combine with input.
	player.position = TownshipV01.SLIDE_CENTER + Vector2(-20, -190)
	await wait_frames(18)
	await drive(player, Vector2.DOWN, 85)

	# Walk through the open Fish Market canopy without catching on posts.
	player.position = Vector2(405, 35)
	await wait_frames(18)
	await drive(player, Vector2.RIGHT, 92)

	# Dash through the broad Departure Gate and follow the route south.
	player.position = TownshipV01.DEPARTURE_GATE + Vector2(0, -190)
	await wait_frames(18)
	await drive(player, Vector2.DOWN, 125, true)

	# Finish at the marked Frozen Coast boundary without starting new content.
	player.position = TownshipV01.DEPARTURE_BOUNDARY + Vector2(0, -230)
	await wait_frames(30)
	player.input_source.touch_movement = Vector2.DOWN
	await wait_frames(35)
	player.input_source.touch_movement = Vector2.ZERO
	await wait_frames(30)
	quit(0)
