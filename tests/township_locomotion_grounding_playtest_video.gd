extends SceneTree
## Short real-runtime route for Township Locomotion Grounding V1 review.

func _initialize() -> void:
	call_deferred("_run")

func wait_frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame

func drive(player: PenguinPlayer, direction: Vector2, frames: int) -> void:
	player.input_source.touch_movement = direction.normalized()
	await wait_frames(frames)
	player.input_source.touch_movement = Vector2.ZERO
	await wait_frames(18)

func _run() -> void:
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	run.player_count = 2
	root.add_child(run)
	await wait_frames(80)
	run.get_node("Overlay").visible = false
	run.get_node("HUD").visible = false
	var players: Array[PenguinPlayer] = run.party.members()
	var p1 := players[0]
	var p2 := players[1]

	# Normal 220 px/s Waddle and Square curb up/down.
	p1.position = Vector2(0, 410)
	p2.position = Vector2(65, 440)
	await wait_frames(24)
	await drive(p1, Vector2.UP, 64)
	await drive(p1, Vector2.DOWN, 64)

	# Great Hall approach: Square level one to the step/terrace level two.
	p1.position = Vector2(44, -250)
	await wait_frames(24)
	await drive(p1, Vector2.UP, 64)
	await drive(p1, Vector2.DOWN, 64)

	# Workshop terrace and the clear Nurse passage.
	p1.position = Vector2(-300, -95)
	await wait_frames(24)
	await drive(p1, Vector2.LEFT, 66)
	await drive(p1, Vector2.RIGHT, 66)
	p1.position = Vector2(-644, 670)
	await wait_frames(48)

	# The existing snow-slide pose and motion remain authoritative.
	p1.position = TownshipV01.SLIDE_CENTER + Vector2(-15, -190)
	await wait_frames(20)
	await drive(p1, Vector2.DOWN, 82)

	# Two players cross different levels at once; their presentation remains local.
	p1.position = Vector2(0, 410)
	p2.position = Vector2(-300, -95)
	p1.input_source.touch_movement = Vector2.UP
	p2.input_source.touch_movement = Vector2.LEFT
	await wait_frames(66)
	p1.input_source.touch_movement = Vector2.ZERO
	p2.input_source.touch_movement = Vector2.ZERO
	await wait_frames(42)
	quit(0)
