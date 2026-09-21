extends SceneTree
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	arena.player_count = 4
	root.add_child(arena)
	await process_frame
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	var players: Array[PenguinPlayer] = arena.party.members()
	var viewport_size: Vector2 = root.get_visible_rect().size
	check(arena.get_node("IceArenaVisual").floor_rect.size == viewport_size, "floor covers entire viewport")
	check(players[0].arena_bounds.size == viewport_size - Vector2(56, 56), "movement reaches every screen edge with body inset")
	check(arena.get_node("Camera").zoom == Vector2.ONE and arena.get_node("Camera").offset == Vector2.ZERO, "camera reserves no HUD strip")
	arena.encounter._spawn_enemy()
	for node: Node in arena.get_node("Actors").get_children():
		if node is ArenaEnemy:
			check(node.arena_bounds == players[0].arena_bounds, "spawned enemy shares room bounds")
	var cards: Array[PlayerCornerHUD] = []
	var banner: LocationBanner
	for node: Node in arena.get_node("HUD").get_children():
		if node is PlayerCornerHUD:
			cards.append(node)
		elif node is LocationBanner:
			banner = node
	check(cards.size() == 4, "one corner card per player")
	for index: int in range(cards.size()):
		check(cards[index].anchor_left == float(index % 2) and cards[index].anchor_top == float(index / 2), "card assigned to correct corner")
	players[1].health.take_damage(DamageEvent.new(25))
	arena.get_node("Wallet").credit(2, 17)
	await process_frame
	check(cards[1]._health.value == 75 and cards[1]._counts.text.contains("17 flakes"), "corner card reflects actual health and personal wallet")
	cards[1].selected.emit()
	check(arena.get_node("HUD")._sheet.player == players[1], "selecting portrait opens correct player's shop")
	arena.get_node("HUD")._sheet.queue_free()
	await create_timer(2.8).timeout
	check(not is_instance_valid(banner), "arrival banner removes itself after fading")
	arena.free()
	print("FULLSCREEN HUD TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
