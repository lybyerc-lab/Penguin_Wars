extends SceneTree
## Focused gameplay-feel checks for Township V0.2.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func service_of(run: Node2D, kind: TownService.Kind) -> TownService:
	for service: TownService in run.services():
		if service.kind == kind:
			return service
	return null

func settle(frames: int = 4) -> void:
	for frame: int in range(frames):
		await physics_frame

func _run() -> void:
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	run.player_count = 4
	root.add_child(run)
	await settle(5)

	var camera := run.get_node("Camera") as PartyCamera
	var players: Array[PenguinPlayer] = run.party.members()
	check(camera.follow_party, "Township keeps party-follow camera mode")
	check(camera.framed_size == Vector2(1380, 760), "normal Township framing is modestly wider")
	for index: int in range(players.size()):
		players[index].position = Vector2(index * 42 - 63, 80)
	run.call("_process", 0.0)
	camera._process(10.0)
	var normal_zoom: float = camera.zoom.x
	check(normal_zoom < 1.0 and normal_zoom > 0.82, "normal camera shows more context without making players tiny")

	var hall := service_of(run, TownService.Kind.TOWN_HALL)
	var smith := service_of(run, TownService.Kind.BLACKSMITH)
	var nurse := service_of(run, TownService.Kind.NURSE)
	var market := service_of(run, TownService.Kind.SHOP)
	check(hall != null and smith != null and nurse != null and market != null, "all service approaches exist")
	check(hall.position.y > TownshipV01.GREAT_HALL.end.y, "Great Hall approach faces south toward the square")
	check(smith.position.y > TownshipV01.WORKSHOP.end.y, "Workshop approach faces its direct square path")
	check(nurse.position.x > TownshipV01.HOME_A.end.x, "home service approach faces east toward the square")
	check(market.position.x <= TownshipV01.MARKET_COUNTER.position.x, "Fish Market approach uses the open square-facing end")

	var focus_offsets: Array[Vector2] = [Vector2(-45, -20), Vector2(45, -20), Vector2(-45, 30), Vector2(45, 30)]
	for index: int in range(players.size()):
		players[index].position = hall.position + focus_offsets[index]
	run.call("_process", 0.0)
	check(camera.focus_active, "nearby co-op party activates building focus from a service pad")
	check(camera.focus_point == hall.camera_focus_point, "Great Hall supplies its own focus point")
	camera._process(10.0)
	check(camera.zoom.x > normal_zoom, "building focus modestly tightens framing")

	players[3].position = hall.position + Vector2(TownService.CAMERA_GROUP_RADIUS + 80.0, 0)
	run.call("_process", 0.0)
	check(not camera.focus_active, "one nearby user cannot pull a distant co-op party into building focus")
	players[3].position = hall.position + focus_offsets[3]
	for player: PenguinPlayer in players:
		player.position += Vector2(0, 160)
	run.call("_process", 0.0)
	check(not camera.focus_active, "camera focus clears when the party leaves the pad")

	var township := run.get_node("Places/TownshipV01") as TownshipV01
	var slide := township.get_node("SnowSlide") as TownshipSnowSlide
	var rider: PenguinPlayer = players[0]
	rider.position = TownshipV01.SLIDE_CENTER
	rider.input_source.touch_movement = Vector2.ZERO
	await settle(6)
	var visual := rider.get_node("CharacterVisual") as CharacterVisual
	check(bool(rider.get_meta(TownshipSnowSlide.META_ACTIVE, false)), "slide marks its active rider locally")
	check(visual.current_state == CharacterVisual.State.IDLE, "slide suppresses MOVE/Waddle presentation")
	check(not visual.animated_sprite.is_playing(), "slide holds a stable production frame")
	check(is_equal_approx(rider.rotation, 0.0), "slide never rotates the gameplay root")
	check(is_equal_approx(visual._pivot.rotation, CharacterVisual.TOWNSHIP_SLIDE_LEAN), "slide applies only the small presentation lean")

	rider.position = Vector2(0, 80)
	rider.input_source.touch_movement = Vector2.RIGHT
	await settle(6)
	check(not rider.has_meta(TownshipSnowSlide.META_ACTIVE), "leaving the slide clears its local presentation flag")
	check(visual.current_state == CharacterVisual.State.MOVE, "normal Waddle resumes immediately after the slide")
	check(visual.animated_sprite.is_playing(), "production MOVE playback resumes after the held slide pose")
	check(is_equal_approx(visual.animated_sprite.speed_scale, CharacterVisual.MOVE_PLAYBACK_MULTIPLIER), "Waddle keeps the approved 1.15x cadence")

	run.free()
	print("TOWNSHIP V0.2 TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
