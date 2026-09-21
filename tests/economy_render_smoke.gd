extends SceneTree
## Controlled art/UI fixture; credits are test setup, not starting run currency.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	var four_players: bool = "--four-players" in OS.get_cmdline_user_args()
	if four_players:
		arena.player_count = 4
	root.add_child(arena)
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	var players: Array[PenguinPlayer] = arena.party.members()
	players[0].position = Vector2(-70, 40)
	players[1].position = Vector2(70, 40)
	players[0].dash.facing = Vector2.DOWN
	arena.get_node("Wallet").credit(1, 24)
	arena.get_node("Wallet").credit(2, 18)
	arena.get_node("Builder").build(1)
	players[0].apply_upgrade(load("res://resources/upgrades/harvest.tres"))
	for position: Vector2 in [Vector2(-220, 80), Vector2(-180, 115), Vector2(230, 115)]:
		arena.get_node("Loot").spawn_pickup(position, RunPickup.Kind.SNOWFLAKE, 2)
	arena.get_node("Loot").spawn_pickup(Vector2(-210, 140), RunPickup.Kind.HEALTH, 25)
	arena.encounter.state = EncounterDirector.State.INTERMISSION
	for frame: int in range(210):
		await process_frame
	await RenderingServer.frame_post_draw
	var path: String = "res://docs/economy-four-players.png" if four_players else "res://docs/economy-preview.png"
	var result: Error = root.get_texture().get_image().save_png(path)
	print("ECONOMY RENDER: ", "PASS" if result == OK else "FAIL")
	quit(0 if result == OK else 1)
