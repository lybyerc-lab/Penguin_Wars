extends SceneTree
## Uses the real renderer; do not run with --headless. Controlled fixtures of
## the town and two cave rooms, not a playthrough.
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

func _run() -> void:
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	root.add_child(run)
	# Past the arrival banner, so the fixture shows the town at rest.
	await settle(150)
	var players: Array[PenguinPlayer] = run.party.members()
	run.get_node("Wallet").credit(1, 26)
	run.get_node("Wallet").credit(2, 14)
	# Park one penguin at the nurse and one at the hall so both panel kinds show.
	for service: TownService in run.services():
		if service.kind == TownService.Kind.NURSE:
			players[0].position = service.position + Vector2(0, 30)
		elif service.kind == TownService.Kind.TOWN_HALL:
			players[1].position = service.position + Vector2(0, 30)
	await settle(12)
	var town_result: Error = await shot("res://docs/town-preview.png")

	# Entrance room, mid fight.
	travel(run, run.gates()[0])
	await settle(120)
	var cave_result: Error = await shot("res://docs/cave-entrance.png")

	# Clear the room so the branch signposts are readable, then take the seam.
	var director: EncounterDirector = run.encounter
	director.auto_advance = true
	for step: int in range(200):
		director._physics_process(10.0)
		for node: Node in get_nodes_in_group("enemies"):
			(node as ArenaEnemy).health.take_damage(DamageEvent.new(1000, 1))
		await process_frame
		if director.state == EncounterDirector.State.COMPLETE:
			break
	director.auto_advance = false
	players[0].position = Vector2(-120, 60)
	players[1].position = Vector2(120, 60)
	await settle(90)
	var branch_result: Error = await shot("res://docs/cave-branch.png")

	travel(run, run.gates()[0])
	await settle(30)
	players[0].position = Vector2(-90, 40)
	players[1].position = Vector2(90, 40)
	await settle(20)
	var seam_result: Error = await shot("res://docs/cave-supply-room.png")

	var failed: bool = town_result != OK or cave_result != OK or branch_result != OK or seam_result != OK
	print("TOWN RENDER SMOKE: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
