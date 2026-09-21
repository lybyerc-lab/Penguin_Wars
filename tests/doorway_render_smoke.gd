extends SceneTree
## Uses the real renderer; do not run with --headless. Captures doorway fixtures:
## cave mouths, locked ice barricades, unlocked passages, branching environmental
## storytelling, boss blockade, 4-player waiting state, and mobile.

func _initialize() -> void:
	call_deferred("_run")

func shot(path: String) -> Error:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image().save_png(path)

func settle(frames: int) -> void:
	for frame: int in range(frames):
		await process_frame

func travel(run: Node2D, gate: PartyGate) -> void:
	for player: PenguinPlayer in run.party.members(true):
		player.position = gate.position
	gate._physics_process(PartyGate.DWELL + 0.2)

func clear_room(run: Node2D) -> void:
	var director: EncounterDirector = run.encounter
	director.auto_advance = true
	for step: int in range(200):
		director._physics_process(10.0)
		for node: Node in get_nodes_in_group("enemies"):
			if node is ArenaEnemy:
				node.health.take_damage(DamageEvent.new(1000, 1))
		await process_frame
		if director.state == EncounterDirector.State.COMPLETE:
			break
	director.auto_advance = false

func _run() -> void:
	print("Starting Doorway Render Smoke...")
	var captures: Array[Error] = []

	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	root.add_child(run)
	await settle(150)

	var players: Array[PenguinPlayer] = run.party.members()

	# 1. Kelphollow Cave Mouth (passages at bottom of town)
	players[0].position = Vector2(-40, 220)
	players[1].position = Vector2(40, 220)
	await settle(15)
	captures.append(await shot("res://docs/doorway-kelphollow-cave-mouth.png"))

	# 2. Hollow Shelf Entrance with locked left/right openings (ice barricades)
	travel(run, run.gates()[0])
	await settle(60)
	players[0].position = Vector2(-200, 50)
	players[1].position = Vector2(200, 50)
	await settle(20)
	captures.append(await shot("res://docs/doorway-shelf-mouth-locked.png"))

	# 3. Hollow Shelf after room clear: unlocked openings (LEFT: glitter, RIGHT: cracked)
	await clear_room(run)
	players[0].position = Vector2(-150, 0)
	players[1].position = Vector2(150, 0)
	await settle(60)
	captures.append(await shot("res://docs/doorway-shelf-mouth-unlocked.png"))

	# 4. Glitter Seam (supply room)
	var seam_gate: PartyGate = null
	for gate: PartyGate in run.gates():
		if gate.exit.target_id == &"glitter_seam":
			seam_gate = gate
			break
	travel(run, seam_gate)
	await settle(60)
	players[0].position = Vector2(-80, 20)
	players[1].position = Vector2(80, 20)
	await settle(20)
	captures.append(await shot("res://docs/doorway-glitter-seam.png"))

	# 5. Black Ledge during Frostbreaker (boss alive, exit barricaded)
	travel(run, run.gates()[0])
	await settle(60)
	players[0].position = Vector2(-120, 80)
	players[1].position = Vector2(120, 80)
	await settle(20)
	captures.append(await shot("res://docs/doorway-black-ledge-boss.png"))

	# 6. Black Ledge after boss defeat (exit unblocked and open)
	await clear_room(run)
	players[0].position = Vector2(-60, 200)
	players[1].position = Vector2(60, 200)
	await settle(60)
	captures.append(await shot("res://docs/doorway-black-ledge-cleared.png"))

	run.free()

	# 7. Hollow Shelf branching to Cracked Gallery
	var gallery_run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	root.add_child(gallery_run)
	await settle(100)
	travel(gallery_run, gallery_run.gates()[0])
	await settle(30)
	await clear_room(gallery_run)
	var gallery_gate: PartyGate = null
	for gate: PartyGate in gallery_run.gates():
		if gate.exit.target_id == &"cracked_gallery":
			gallery_gate = gate
			break
	travel(gallery_run, gallery_gate)
	await settle(60)
	gallery_run.party.members()[0].position = Vector2(-80, 50)
	gallery_run.party.members()[1].position = Vector2(80, 50)
	await settle(20)
	captures.append(await shot("res://docs/doorway-cracked-gallery.png"))
	gallery_run.free()

	# 8. 4-player co-op waiting state ("WAITING FOR P4")
	var four_run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	four_run.player_count = 4
	root.add_child(four_run)
	await settle(100)
	travel(four_run, four_run.gates()[0])
	await settle(30)
	await clear_room(four_run)
	var f_players: Array[PenguinPlayer] = four_run.party.members()
	var target_gate: PartyGate = four_run.gates()[0]
	# Place players 1, 2, 3 inside the threshold, player 4 far away
	f_players[0].global_position = target_gate.global_position + Vector2(25, 0)
	f_players[1].global_position = target_gate.global_position + Vector2(25, -25)
	f_players[2].global_position = target_gate.global_position + Vector2(25, 25)
	f_players[3].global_position = Vector2(0, 0)
	target_gate._physics_process(0.1)
	await settle(20)
	captures.append(await shot("res://docs/doorway-waiting-coop.png"))
	four_run.free()

	# 9. Mobile preview
	var mobile_run: Node2D = load("res://scenes/arena/test_arena.tscn").instantiate()
	mobile_run.mobile_preview = true
	root.add_child(mobile_run)
	await settle(60)
	captures.append(await shot("res://docs/doorway-mobile.png"))
	mobile_run.free()

	var any_failed: bool = false
	for err: Error in captures:
		if err != OK:
			any_failed = true
			break

	print("DOORWAY RENDER SMOKE: ", "FAIL" if any_failed else "PASS")
	quit(1 if any_failed else 0)
