extends SceneTree
## Uses the real renderer; do not run with --headless. A controlled boss pose,
## not a fought encounter.
func _initialize() -> void:
	call_deferred("_run")

func settle(frames: int) -> void:
	for frame: int in range(frames):
		await process_frame

func travel(run: Node2D, gate: PartyGate) -> void:
	for player: PenguinPlayer in run.party.members(true):
		player.position = gate.position
	gate._physics_process(PartyGate.DWELL + 0.2)

func clear_waves(run: Node2D) -> void:
	var director: EncounterDirector = run.encounter
	director.auto_advance = true
	for step: int in range(200):
		director._physics_process(10.0)
		for node: Node in get_nodes_in_group("enemies"):
			if node is ArenaBoss:
				continue
			(node as ArenaEnemy).health.take_damage(DamageEvent.new(1000, 1))
		await process_frame
		if director.state in [EncounterDirector.State.BOSS, EncounterDirector.State.COMPLETE]:
			break
	director.auto_advance = false

func _run() -> void:
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	root.add_child(run)
	await settle(10)
	# Straight down the supply branch to the final room.
	travel(run, run.gates()[0])
	await settle(4)
	await clear_waves(run)
	travel(run, run.gates()[0])
	await settle(4)
	travel(run, run.gates()[0])
	await settle(4)
	await clear_waves(run)
	var boss: ArenaBoss = run.encounter.active_boss
	if boss == null:
		print("BOSS RENDER: FAIL")
		quit(1)
		return
	# Freeze a readable charge warning rather than chasing live timing.
	for node: Node in run.find_children("*", "", true, false):
		node.set_physics_process(false)
	var players: Array[PenguinPlayer] = run.party.members()
	boss.position = Vector2(0, -60)
	players[0].position = Vector2(-150, 90)
	players[1].position = Vector2(150, 90)
	var brain := boss.behavior as BossBehavior
	brain.remaining = 0.0
	brain.movement(boss, players[0], 0.01)
	boss.health.take_damage(DamageEvent.new(180, 1))
	# Long enough for the arrival banner to have faded out entirely.
	await settle(200)
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png("res://docs/cave-boss.png")
	print("BOSS RENDER: ", "PASS" if result == OK else "FAIL")
	quit(0 if result == OK else 1)
