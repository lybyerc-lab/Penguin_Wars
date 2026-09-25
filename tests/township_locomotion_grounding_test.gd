extends SceneTree
## Focused V1 checks for velocity-driven Waddle and local Township elevation.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func settle(frames: int = 5) -> void:
	for frame: int in range(frames):
		await physics_frame

func process_visual(visual: CharacterVisual, seconds: float = 0.0) -> void:
	visual._process_player(seconds)

func check_waddle_speed(player: PenguinPlayer, visual: CharacterVisual, speed: float, label: String) -> void:
	player.velocity = Vector2(speed, 0.0)
	process_visual(visual)
	var expected: float = clampf(
		speed / CharacterVisual.WADDLE_REFERENCE_SPEED,
		CharacterVisual.WADDLE_MIN_PLAYBACK_MULTIPLIER,
		CharacterVisual.WADDLE_MAX_PLAYBACK_MULTIPLIER
	)
	check(visual.current_state == CharacterVisual.State.MOVE, "%s speed selects MOVE" % label)
	check(is_equal_approx(visual.animated_sprite.speed_scale, expected), "%s base Waddle rate follows actual velocity" % label)
	check(is_equal_approx(visual.scarf_sprite.speed_scale, expected), "%s scarf Waddle rate stays synchronized" % label)

func _run() -> void:
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	run.player_count = 4
	root.add_child(run)
	await settle(8)

	var township := run.get_node("Places/TownshipV01") as TownshipV01
	var players: Array[PenguinPlayer] = run.party.members()
	var p1 := players[0]
	var p2 := players[1]
	var p3 := players[2]
	var v1 := p1.get_node("CharacterVisual") as CharacterVisual
	var v2 := p2.get_node("CharacterVisual") as CharacterVisual
	var v3 := p3.get_node("CharacterVisual") as CharacterVisual

	# Injected velocities are presentation-test data only. Player.speed remains
	# locked at 220 and no gameplay debug setting is introduced.
	check_waddle_speed(p1, v1, 55.0, "25%")
	check_waddle_speed(p1, v1, 110.0, "50%")
	check_waddle_speed(p1, v1, 220.0, "100%")
	check_waddle_speed(p1, v1, 440.0, "fast clamp")
	check(is_equal_approx(v1.animated_sprite.speed_scale, CharacterVisual.WADDLE_MAX_PLAYBACK_MULTIPLIER), "fast Waddle uses a sensible maximum clamp")
	p1.velocity = Vector2.ZERO
	process_visual(v1)
	check(v1.current_state == CharacterVisual.State.IDLE, "zero movement returns to IDLE")
	check(is_equal_approx(v1.animated_sprite.speed_scale, 1.0), "Idle retains authored playback rate")

	p1.dash.direction = Vector2.RIGHT
	p1.dash.remaining = p1.dash.duration
	p1.velocity = Vector2(680, 0)
	process_visual(v1)
	check(v1.current_state == CharacterVisual.State.DASH, "DASH overrides velocity-driven Waddle")
	check(is_equal_approx(v1.animated_sprite.speed_scale, 1.0), "DASH retains its authored playback rate")
	p1.dash.remaining = 0.0
	# Clear the authored dash hold before exercising the independent slide state.
	process_visual(v1, v1.get_state_animation_duration(CharacterVisual.State.DASH) + 0.1)
	p1.velocity = Vector2.ZERO
	process_visual(v1)

	# Three independent locations exercise square, workshop, and base ground.
	p1.position = Vector2(0, 80)
	p2.position = Vector2(-715, -95)
	p3.position = Vector2(700, 700)
	var root_before: Array[Vector2] = [p1.global_position, p2.global_position, p3.global_position]
	township._physics_process(0.0)
	for frame: int in range(12):
		process_visual(v1, 1.0 / 60.0)
		process_visual(v2, 1.0 / 60.0)
		process_visual(v3, 1.0 / 60.0)
	check(township.elevation_region_at(p1.position) == &"town_square", "Town Square curb region is covered")
	check(township.elevation_region_at(p2.position) == &"workshop_terrace", "Workshop terrace region is covered")
	check(township.elevation_region_at(p3.position) == &"base_ground", "base ground remains level zero")
	check(v1.get_township_elevation_level() == 1 and is_equal_approx(v1._pivot.position.y, -4.0), "P1 rises subtly on the square")
	check(v2.get_township_elevation_level() == 2 and is_equal_approx(v2._pivot.position.y, -8.0), "P2 rises independently on the workshop terrace")
	check(v3.get_township_elevation_level() == 0 and is_equal_approx(v3._pivot.position.y, 0.0), "P3 stays grounded on base snow")
	check(p1.global_position == root_before[0] and p2.global_position == root_before[1] and p3.global_position == root_before[2], "elevation changes never move gameplay roots")

	p1.position = Vector2(44, -470)
	township._physics_process(0.0)
	for frame: int in range(12):
		process_visual(v1, 1.0 / 60.0)
	check(township.elevation_region_at(p1.position) == &"great_hall_steps", "Great Hall approach region is covered")
	check(v1.get_township_elevation_level() == 2 and is_equal_approx(v1._pivot.position.y, -8.0), "Great Hall step level persists while standing")

	p1.position = Vector2(0, 800)
	township._physics_process(0.0)
	for frame: int in range(12):
		process_visual(v1, 1.0 / 60.0)
	check(v1.get_township_elevation_level() == 0 and is_equal_approx(v1._pivot.position.y, 0.0), "leaving a region settles the visual back to base ground")

	p1.position = TownshipV01.SLIDE_CENTER
	p1.input_source.touch_movement = Vector2.ZERO
	await settle(6)
	check(bool(p1.get_meta(TownshipSnowSlide.META_ACTIVE, false)), "slide still marks its active rider")
	check(v1.current_state == CharacterVisual.State.IDLE, "slide overrides velocity-driven Waddle presentation")
	check(is_equal_approx(v1._pivot.position.y, 0.0), "slide suppresses elevation visual offset")

	run.free()
	print("TOWNSHIP LOCOMOTION GROUNDING TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
