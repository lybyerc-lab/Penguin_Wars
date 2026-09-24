extends SceneTree
## One real-renderer capture of four centered ground indicators.

const OUTPUT := "res://docs/character-production-review/ground-indicator-v1/01-four-player-idle.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Ground indicator review requires the real renderer")
		quit(1)
		return
	var arena := (load("res://scenes/arena/test_arena.tscn") as PackedScene).instantiate() as Node2D
	arena.set("player_count", 4)
	root.add_child(arena)
	await process_frame
	var players: Array[PenguinPlayer] = (arena.get_node("Party") as PartyRoster).members()
	if players.size() != 4:
		push_error("Expected four players")
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
	for i in range(4):
		var player := players[i]
		player.set_physics_process(false)
		player.weapon_rack.set_physics_process(false)
		player.position = Vector2(-210 + i * 140, 0)
		player.velocity = Vector2.ZERO
		var label := Label.new()
		label.text = "P%d  IDLE" % (i + 1)
		label.position = player.position + Vector2(-40, -100)
		label.modulate = player.identity.tint
		arena.add_child(label)
	for frame in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var result := root.get_texture().get_image().save_png(OUTPUT)
	print("GROUND INDICATOR REVIEW: ", "PASS" if result == OK else "FAIL", " ", OUTPUT)
	quit(0 if result == OK else 1)
