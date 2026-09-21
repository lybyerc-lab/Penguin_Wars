extends SceneTree
## Uses the real renderer; do not run with --headless.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	root.add_child(arena)
	for frame: int in range(180):
		await process_frame
	# Controlled combat pose exercises live VFX without relying on spawn timing.
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/combat-live.png")
	var players: Array[PenguinPlayer] = arena.party.members()
	for player: PenguinPlayer in players:
		player.set_physics_process(false)
		player.weapon.set_physics_process(false)
	players[0].dash.tick(0.0, Vector2.LEFT, true, true)
	players[0].queue_redraw()
	for offset: Vector2 in [Vector2(65, 0), Vector2(75, 40)]:
		var enemy: ArenaEnemy = load("res://scenes/actors/enemy.tscn").instantiate()
		enemy.party = arena.party
		enemy.position = players[1].position + offset
		arena.get_node("Actors").add_child(enemy)
	players[1].weapon._physics_process(2.0)
	for frame: int in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png("res://docs/arena-preview.png")
	print("RENDER SMOKE: ", "PASS" if result == OK else "FAIL")
	quit(0 if result == OK else 1)
