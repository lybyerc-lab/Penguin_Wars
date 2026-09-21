extends SceneTree
## Controlled visual fixtures, not a live balance/playthrough test.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	root.add_child(arena)
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	var players: Array[PenguinPlayer] = arena.party.members()
	players[0].position = Vector2(-120, 80)
	players[1].position = Vector2(0, 90)
	var charger: ArenaEnemy = load("res://scenes/actors/charging_seal.tscn").instantiate()
	charger.party = arena.party
	charger.position = Vector2(170, -70)
	arena.get_node("Actors").add_child(charger)
	charger.set_physics_process(false)
	var ranged: ArenaEnemy = load("res://scenes/actors/snowball_thrower.tscn").instantiate()
	ranged.party = arena.party
	ranged.position = Vector2(-300, -80)
	arena.get_node("Actors").add_child(ranged)
	ranged.set_physics_process(false)
	arena.encounter.alive_count = 2
	charger.behavior.movement(charger, players[1], 0.01)
	ranged.behavior.movement(ranged, players[0], 1.0)
	for frame: int in range(60):
		await process_frame
	await RenderingServer.frame_post_draw
	var warning_result: Error = root.get_texture().get_image().save_png("res://docs/enemy-warnings.png")
	ranged.behavior.movement(ranged, players[0], 0.71)
	charger.set_physics_process(true)
	charger.behavior.remaining = 0.0
	for frame: int in range(12):
		await physics_frame
	await RenderingServer.frame_post_draw
	var attack_result: Error = root.get_texture().get_image().save_png("res://docs/enemy-attacks.png")
	print("ENEMY RENDER: ", "PASS" if warning_result == OK and attack_result == OK else "FAIL")
	quit(0 if warning_result == OK and attack_result == OK else 1)
