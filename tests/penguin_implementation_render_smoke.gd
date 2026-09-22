extends SceneTree
## Real OpenGL renderer smoke test for Playable Penguin Implementation v1 (Phase B).
## Generates all required proof captures under docs/.

func _initialize() -> void:
	call_deferred("_run")

func _cleanup_hit_effects(arena: Node2D) -> void:
	for node in [arena, arena.get_node("Actors")]:
		for child in node.get_children():
			if child is HitEffect:
				child.queue_free()

func _run() -> void:
	var scene: PackedScene = load("res://scenes/arena/test_arena.tscn")
	var arena: Node2D = scene.instantiate()
	root.add_child(arena)

	# Allow arena and HUD to initialize
	for frame: int in range(60):
		await process_frame

	var camera: Camera2D = arena.get_node("Camera") as Camera2D
	var hud: CanvasLayer = arena.get_node_or_null("HUD") as CanvasLayer
	var party: PartyRoster = arena.party
	var players: Array[PenguinPlayer] = party.members()
	var p1: PenguinPlayer = players[0]
	var p2: PenguinPlayer = players[1]
	var v1: CharacterVisual = p1.get_node("CharacterVisual") as CharacterVisual
	var v2: CharacterVisual = p2.get_node("CharacterVisual") as CharacterVisual

	# Stop background combat spawning for controlled captures
	arena.encounter.auto_advance = false
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	for frame: int in range(10):
		await process_frame

	# Freeze players for controlled presentation
	p1.set_physics_process(false)
	p2.set_physics_process(false)

	# Disable camera auto-reframing for close-up state captures
	camera.set_process(false)
	if hud != null:
		hud.visible = false

	# Hide equipped weapons during character pose showcase so anatomy/shadows are unobstructed
	p1.weapon_rack.visible = false
	p2.weapon_rack.visible = false

	# =========================================================================
	# Capture 1: docs/penguin-implemented-idle.png (Close-up view of IDLE stance)
	# =========================================================================
	p1.position = Vector2(0, 0)
	p1.velocity = Vector2.ZERO
	p2.position = Vector2(1000, 1000) # Move P2 offscreen
	camera.position = Vector2(0, -6)
	camera.zoom = Vector2(3.5, 3.5)

	p1.health.current = 100.0
	v1.current_state = CharacterVisual.State.IDLE
	v1._time = 1.2
	v1._apply_pose_idle(0.0)

	for frame: int in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var err1: Error = root.get_texture().get_image().save_png("res://docs/penguin-implemented-idle.png")
	print("CAPTURE 1 (IDLE): ", "OK" if err1 == OK else "FAILED")

	# =========================================================================
	# Capture 2: docs/penguin-implemented-move.png (Close-up view of WADDLE motion)
	# =========================================================================
	p1.velocity = Vector2(160, 0)
	v1.current_state = CharacterVisual.State.WADDLE
	v1._waddle_time = 0.13 # Peak alternating step
	v1._apply_pose_waddle(0.0)

	for frame: int in range(2):
		await process_frame
	await RenderingServer.frame_post_draw
	var err2: Error = root.get_texture().get_image().save_png("res://docs/penguin-implemented-move.png")
	print("CAPTURE 2 (WADDLE): ", "OK" if err2 == OK else "FAILED")

	# Settle back from waddle
	p1.velocity = Vector2.ZERO
	v1.current_state = CharacterVisual.State.IDLE
	v1._apply_pose_idle(0.0)
	for frame: int in range(5):
		await process_frame

	# =========================================================================
	# Capture 3: docs/penguin-implemented-dash-hit.png (Side-by-side DASH & HIT)
	# =========================================================================
	p1.position = Vector2(-55, 0)
	p2.position = Vector2(55, 0)
	camera.position = Vector2(0, -6)
	camera.zoom = Vector2(3.0, 3.0)

	# P1 in active DASH forward
	v1.current_state = CharacterVisual.State.DASH
	p1.dash.direction = Vector2.RIGHT
	p1.dash.remaining = 0.14
	v1._apply_pose_dash(0.0)

	# P2 in active HIT recoil with squeezed eyes and open mouth
	p2.health.take_damage(DamageEvent.new(10))
	v2.current_state = CharacterVisual.State.HIT
	v2._hit_timer = 0.11
	v2._apply_pose_hit(0.0)

	_cleanup_hit_effects(arena)

	for frame: int in range(2):
		await process_frame
	_cleanup_hit_effects(arena)
	await RenderingServer.frame_post_draw
	var err3: Error = root.get_texture().get_image().save_png("res://docs/penguin-implemented-dash-hit.png")
	print("CAPTURE 3 (DASH & HIT): ", "OK" if err3 == OK else "FAILED")

	# Reset dash and hit
	p1.dash.remaining = 0.0
	p2.position = Vector2(1000, 1000)

	# =========================================================================
	# Capture 4: docs/penguin-implemented-downed.png (DOWNED state with halo)
	# =========================================================================
	p1.position = Vector2(0, 0)
	camera.position = Vector2(0, -6)
	camera.zoom = Vector2(3.2, 3.2)

	# Kill P1 to trigger DOWNED state
	p1.health.take_damage(DamageEvent.new(1000))
	v1.current_state = CharacterVisual.State.DOWNED
	v1._time = 2.0
	v1._apply_pose_downed(0.0)

	_cleanup_hit_effects(arena)

	for frame: int in range(8):
		await process_frame
		_cleanup_hit_effects(arena)
	await RenderingServer.frame_post_draw
	var err4: Error = root.get_texture().get_image().save_png("res://docs/penguin-implemented-downed.png")
	print("CAPTURE 4 (DOWNED): ", "OK" if err4 == OK else "FAILED")

	# =========================================================================
	# Capture 5: docs/penguin-implemented-revive.png (REVIVE get-up sequence)
	# =========================================================================
	# Trigger revive signal
	p1.health.current = 50.0
	p1.health.revived.emit(50.0)
	v1.current_state = CharacterVisual.State.REVIVE
	v1._revive_timer = 0.18 # Mid-pushup
	v1._apply_pose_revive(0.0)

	_cleanup_hit_effects(arena)

	for frame: int in range(2):
		await process_frame
		_cleanup_hit_effects(arena)
	await RenderingServer.frame_post_draw
	var err5: Error = root.get_texture().get_image().save_png("res://docs/penguin-implemented-revive.png")
	print("CAPTURE 5 (REVIVE): ", "OK" if err5 == OK else "FAILED")

	# Let revive finish
	for frame: int in range(25):
		await process_frame

	# =========================================================================
	# Capture 6: docs/penguin-implemented-gameplay-scale.png (1:1 actual scale)
	# =========================================================================
	# Restore HUD, weapons, and 1:1 camera in Frostfall Bay
	if hud != null:
		hud.visible = true
	camera.set_process(true)
	p1.weapon_rack.visible = true
	p2.weapon_rack.visible = true

	p1.position = Vector2(-80, 20)
	p2.position = Vector2(60, -20)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2(100, 0)
	p1.health.current = 100.0
	p2.health.current = 100.0

	# Spawn an enemy at typical combat distance to contextualize gameplay
	var enemy: ArenaEnemy = load("res://scenes/actors/enemy.tscn").instantiate()
	enemy.party = arena.party
	enemy.position = Vector2(170, 0)
	arena.get_node("Actors").add_child(enemy)

	# Re-apply room framing
	RoomSpace.apply(arena.room, party, arena.encounter, arena.get_node("Builder"), arena.get_node("Loot"), camera, arena.get_node("IceArenaVisual"), arena.get_node("Actors"))

	for frame: int in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	var err6: Error = root.get_texture().get_image().save_png("res://docs/penguin-implemented-gameplay-scale.png")
	print("CAPTURE 6 (GAMEPLAY SCALE): ", "OK" if err6 == OK else "FAILED")

	var all_ok: bool = (err1 == OK and err2 == OK and err3 == OK and err4 == OK and err5 == OK and err6 == OK)
	print("ALL RENDER PROOF CAPTURES: ", "PASS" if all_ok else "FAIL")
	quit(0 if all_ok else 1)
