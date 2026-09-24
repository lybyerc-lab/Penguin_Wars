extends SceneTree
## Verifies Brotato-style fullscreen HUD, PlayerCornerHUD, deterministic geometry,
## camera framing, BossHUD placement, and cave traversal.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func travel(run: Node2D, gate: PartyGate) -> void:
	for player: PenguinPlayer in run.party.members(true):
		player.position = gate.position
	gate._physics_process(PartyGate.DWELL + 0.2)

func _run() -> void:
	# =========================================================================
	# 1. PlayerCornerHUD 1-4 Player Assignment & Structure
	# =========================================================================
	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	arena.player_count = 4
	root.add_child(arena)
	await process_frame

	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)

	var hud: Node = arena.get_node("HUD")
	var cards: Array[PlayerCornerHUD] = []
	for child: Node in hud.get_children():
		if child is PlayerCornerHUD:
			cards.append(child)

	check(cards.size() == 4, "one PlayerCornerHUD per active player (4 players)")
	for index: int in range(cards.size()):
		var right: bool = index % 2 == 1
		var bottom: bool = index >= 2
		check(cards[index].anchor_left == (1.0 if right else 0.0), "P%d card correct horizontal anchor" % (index + 1))
		check(cards[index].anchor_top == (1.0 if bottom else 0.0), "P%d card correct vertical anchor" % (index + 1))
		check(cards[index].player == arena.party.members()[index], "P%d card bound to correct player" % (index + 1))
		check(cards[index]._weapon_row != null, "P%d card has weapon-row slot for future expansion" % (index + 1))

	# =========================================================================
	# 2. Dynamic Card Reflection: Health, Level, Snow
	# =========================================================================
	var players: Array[PenguinPlayer] = arena.party.members()
	players[0].experience.level = 4
	players[1].health.take_damage(DamageEvent.new(30))
	arena.get_node("Wallet").credit(2, 55)
	await process_frame

	check(cards[0]._title.text.contains("LEVEL 4"), "P1 card reflects level change")
	check(is_equal_approx(cards[1]._health.value, 70.0), "P2 card reflects health damage")
	check(cards[1]._counts.text == "❄  55 Snow", "P2 card displays personal Snow balance (not 'flakes')")

	# Selecting card opens BuildSheet
	cards[1].selected.emit()
	check(hud._sheet != null and hud._sheet.player == players[1], "clicking card opens character/build sheet")
	hud._sheet.queue_free()

	# =========================================================================
	# 3. Central Location & Wave Header
	# =========================================================================
	check(hud._location_label != null, "central location label exists")
	check(hud._location_label.text == "FROSTFALL BAY", "location label displays room name")
	check(hud._wave_label != null and hud._wave_label.text != "", "central wave/state label exists")

	# =========================================================================
	# 4. Camera Framing & Deterministic Room Geometry
	# =========================================================================
	var camera: PartyCamera = arena.get_node("Camera") as PartyCamera
	check(camera != null, "PartyCamera exists")
	check(camera.bottom_reserve == 0.0, "camera reserves no permanent bottom HUD strip on desktop")
	check(camera.zoom.x >= 0.95 and camera.zoom.x <= 1.05, "camera zoom frames arena close to 1.0 (got %f)" % camera.zoom.x)

	var orig_bounds: Rect2 = arena.room.bounds
	check(orig_bounds.size == Vector2(1200, 640), "frostfall_arena logical size is 1200x640")
	# Actually resize the window, then verify room geometry is strictly unchanged.
	var original_window: Vector2i = root.size
	root.size = Vector2i(800, 450)
	await process_frame
	check(root.size != original_window, "the test actually resized the viewport")
	check(arena.room.bounds == orig_bounds, "room bounds are owned by RoomDefinition, not viewport")
	for player: PenguinPlayer in players:
		check(player.arena_bounds == orig_bounds, "player movement bounds strictly match RoomDefinition")
	root.size = original_window
	await process_frame

	# =========================================================================
	# 5. BossHUD Placement & Clearance
	# =========================================================================
	var boss_hud: BossHUD = arena.get_node("BossHUD") as BossHUD
	check(boss_hud != null, "BossHUD is present in test_arena")
	var mini: BossDefinition = load("res://resources/bosses/mini.tres")
	arena.encounter.definition.boss = mini
	arena.encounter._begin_boss()
	await process_frame

	check(boss_hud._root.visible, "BossHUD becomes visible when boss starts")
	check(boss_hud._root.offset_top == 64.0, "BossHUD sits top-center under wave readout (offset_top 64)")
	check(boss_hud._root.offset_left == -260 and boss_hud._root.offset_right == 260, "BossHUD width 520px fits cleanly between corner cards")

	arena.free()
	await process_frame

	# =========================================================================
	# 6. Town and Cave Traversal
	# =========================================================================
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	root.add_child(run)
	await process_frame

	var run_hud: Node = run.get_node("HUD")
	var run_cards: Array[PlayerCornerHUD] = []
	for child: Node in run_hud.get_children():
		if child is PlayerCornerHUD:
			run_cards.append(child)
	check(run_cards.size() == 2, "expedition starts with 2 player corner cards")
	check(run.room.kind == RoomDefinition.Kind.TOWN, "expedition starts in town")
	check(run.room.bounds == TownshipV01.WORLD_BOUNDS, "town room uses the full playable Township bounds")
	check(run.get_node("Camera").follow_party, "Township uses the large-world follow camera mode")

	# Travel to cave mouth (The Hollow Shelf)
	travel(run, run.gates()[0])
	await process_frame
	check(run.room.id == &"shelf_mouth", "traveled to shelf_mouth")
	check(run.room.bounds.size == Vector2(1200, 640), "enlarged shelf_mouth room bounds are 1200x640")
	check(run_hud._location_label.text == "THE HOLLOW SHELF", "HUD location reflects cave room name")

	run.free()
	print("FULLSCREEN HUD TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
