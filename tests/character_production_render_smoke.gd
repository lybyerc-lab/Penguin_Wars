extends SceneTree
## Real renderer review capture of the production character in the live arena.
## Run without --headless.

const OUTPUT_DIR := "res://docs/character-production-review"

func _initialize() -> void:
	call_deferred("_run")

func _capture(name: String) -> Error:
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [OUTPUT_DIR, name]
	var result := root.get_texture().get_image().save_png(path)
	print("CAPTURE ", path, " ", "PASS" if result == OK else "FAIL")
	return result

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Character production review requires the real renderer")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var arena: Node2D = (load("res://scenes/arena/test_arena.tscn") as PackedScene).instantiate() as Node2D
	arena.set("player_count", 4)
	root.add_child(arena)
	await process_frame
	var players: Array[PenguinPlayer] = (arena.get_node("Party") as PartyRoster).members()
	if players.size() != 4:
		push_error("Expected four live players for production art review")
		quit(1)
		return
	(arena.get_node("Encounter") as EncounterDirector).reset()
	(arena.get_node("Encounter") as EncounterDirector).set_physics_process(false)
	for child in arena.get_node("Actors").get_children():
		if child is ArenaEnemy:
			child.queue_free()
	for child in arena.get_children():
		if child is CanvasLayer:
			child.visible = false
	var camera := arena.get_node("Camera") as Camera2D
	camera.set_process(false)
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(2.0, 2.0)
	camera.offset = Vector2.ZERO
	camera.make_current()
	var visuals: Array[CharacterVisual] = []
	var labels: Array[Label] = []
	for i in range(4):
		var player := players[i]
		player.set_physics_process(false)
		player.weapon_rack.set_physics_process(false)
		player.position = Vector2(-210 + i * 140, 0)
		player.velocity = Vector2.ZERO
		var visual := player.get_node("CharacterVisual") as CharacterVisual
		visuals.append(visual)
		if visual.profile == null or visual.animated_sprite.sprite_frames == null:
			push_error("Player %d is not using the production profile" % (i + 1))
			quit(1)
			return
		var label := Label.new()
		label.text = "P%d  IDLE" % (i + 1)
		label.position = player.position + Vector2(-40, -100)
		label.modulate = player.identity.tint
		arena.add_child(label)
		labels.append(label)
	for frame in range(10):
		await process_frame
	var failed := await _capture("01-four-player-idle")
	if failed != OK:
		quit(1)
		return

	# Let the real KO sequence reach its authored settled frame, then show
	# Move and Hit beside the idle player.
	players[3].health.take_damage(DamageEvent.new(1000))
	await create_timer(visuals[3].get_state_animation_duration(CharacterVisual.State.DOWNED) + 0.2).timeout
	if visuals[3].animated_sprite.frame != visuals[3].animated_sprite.sprite_frames.get_frame_count("downed") - 1:
		push_error("KO did not settle on its final production frame")
		quit(1)
		return
	players[1].velocity = Vector2(100, 0)
	players[2].health.take_damage(DamageEvent.new(5))
	labels[1].text = "P2  MOVE"
	labels[2].text = "P3  HIT"
	labels[3].text = "P4  DOWNED"
	for frame in range(9):
		await process_frame
	failed = await _capture("02-idle-move-hit-downed")
	if failed != OK:
		quit(1)
		return

	# Trigger the actual Health revive signal; capture during the authored
	# recovery rather than substituting a static preview image.
	players[3].health.revive(50.0)
	players[0].dash.direction = Vector2.RIGHT
	players[0].dash.remaining = 0.16
	labels[0].text = "P1  DASH"
	labels[2].text = "P3  IDLE"
	labels[3].text = "P4  REVIVE"
	for frame in range(6):
		await process_frame
	failed = await _capture("03-dash-move-revive")
	if failed != OK:
		quit(1)
		return
	for frame in range(18):
		await process_frame
	labels[0].text = "P1  IDLE"
	failed = await _capture("04-revive-rising")
	if failed != OK:
		quit(1)
		return
	for frame in range(24):
		await process_frame
	if visuals[3].current_state != CharacterVisual.State.IDLE:
		push_error("Revive did not release back to idle")
		quit(1)
		return
	labels[0].text = "P1  IDLE"
	labels[1].text = "P2  MOVE"
	labels[3].text = "P4  IDLE"
	failed = await _capture("05-revive-complete")
	print("CHARACTER PRODUCTION RENDER REVIEW: ", "PASS" if failed == OK else "FAIL")
	quit(0 if failed == OK else 1)