extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func capture(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(path)
	assert(result == OK)
func _run() -> void:
	for number: int in [5, 10, 20]:
		var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
		arena.mobile_preview = number == 20
		root.add_child(arena)
		for node: Node in arena.find_children("*", "", true, false):
			node.set_physics_process(false)
		arena.journey.cave_number = number - 1
		arena.encounter.state = EncounterDirector.State.COMPLETE
		arena.journey.next_cave()
		for node: Node in arena.find_children("*", "", true, false):
			node.set_physics_process(false)
		for frame: int in range(210):
			await process_frame
		arena.encounter.wave = 3
		arena.encounter.state = EncounterDirector.State.CLEARING
		arena.encounter.alive_count = 0
		arena.encounter._physics_process(0.1)
		var boss: ArenaBoss = arena.encounter.active_boss
		boss.set_physics_process(false)
		boss.position = Vector2(0, -70)
		var player: PenguinPlayer = arena.party.members()[0]
		player.position = Vector2(-150, 160)
		var brain: BossBehavior = boss.behavior
		brain.remaining = 0
		brain.movement(boss, player, 0.01)
		if number == 10:
			brain.attack = BossBehavior.Attack.VOLLEY
		elif number == 20:
			boss.health.current = boss.health.maximum * 0.4
			brain.attack = BossBehavior.Attack.SLAM
			brain.movement(boss, player, 0.01)
		await capture("res://docs/boss-cave-%d.png" % number)
		if number == 20:
			boss.health.take_damage(DamageEvent.new(100000, 1))
			arena.encounter._physics_process(0.1)
			await capture("res://docs/war-choice.png")
			arena.journey.end_war()
			for frame: int in range(210):
				await process_frame
			await capture("res://docs/war-ending.png")
		arena.free()
	print("BOSS RENDER: PASS")
	quit()
