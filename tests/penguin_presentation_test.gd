extends SceneTree
## Focused verification suite for Approved Broad 2.5D Penguin Player Presentation (Phase B).
## Exit code is nonzero on any failure.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var scene: PackedScene = load("res://scenes/arena/test_arena.tscn")
	var arena: Node2D = scene.instantiate()
	root.add_child(arena)
	await process_frame

	var party: PartyRoster = arena.party
	var players: Array[PenguinPlayer] = party.members()
	check(players.size() >= 2, "arena instantiates player roster")

	var p1: PenguinPlayer = players[0]
	var p2: PenguinPlayer = players[1]

	var v1: CharacterVisual = p1.get_node_or_null("CharacterVisual") as CharacterVisual
	var v2: CharacterVisual = p2.get_node_or_null("CharacterVisual") as CharacterVisual

	check(v1 != null and v2 != null, "CharacterVisual exists on all players")

	# 1. Alive presentation initializes in IDLE
	p1.velocity = Vector2.ZERO
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.IDLE, "initial state is IDLE")
	check(v1._eyes.texture == CharacterVisual.TEX_EYES_ALERT, "IDLE uses alert eyes with dual specular glints")
	check(v1._halo.visible == false, "IDLE halo is hidden")

	# 2. Movement velocity activates WADDLE
	p1.velocity = Vector2(100, 0)
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.WADDLE, "velocity > 10 activates WADDLE")
	check(v1._halo.visible == false, "WADDLE halo is hidden")
	check(v1._facing_direction == 1.0, "moving right faces right")

	# Test moving left changes facing
	p1.velocity = Vector2(-120, 0)
	v1._process_player(0.016)
	check(v1._facing_direction == -1.0, "moving left faces left")

	# Settle back to IDLE
	p1.velocity = Vector2.ZERO
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.IDLE, "stopping returns to IDLE")

	# 3. Dash activates DASH state
	p1.dash.direction = Vector2.RIGHT
	p1.dash.remaining = 0.16
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.DASH, "dash.is_active() activates DASH state")
	check(v1._facing_direction == 1.0, "dash right faces right")
	check(v1._torso.rotation > 0.4, "dash applies strong forward lean")
	check(v1._front_flipper.rotation < -0.5, "dash sweeps flippers back")

	# Dash exits back to IDLE/WADDLE
	p1.dash.remaining = 0.0
	p1.velocity = Vector2.ZERO
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.IDLE, "dash completion returns to IDLE")

	# 4. Damaged activates HIT reaction
	p1.health.take_damage(DamageEvent.new(10))
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.HIT, "taking non-lethal damage enters HIT state")
	check(v1._eyes.texture == CharacterVisual.TEX_EYES_HIT, "HIT uses squeezed shut (> <) eyes")
	check(v1._beak.texture == CharacterVisual.TEX_BEAK_OPEN, "HIT uses open yelling beak with tongue")

	# Hit recovers after duration
	v1._process_player(0.20)
	check(v1.current_state == CharacterVisual.State.IDLE, "HIT recovers back to IDLE")

	# 5. Lethal damage enters DOWNED state
	p1.health.take_damage(DamageEvent.new(1000))
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.DOWNED, "death enters DOWNED state")
	check(v1._eyes.texture == CharacterVisual.TEX_EYES_WOOZY, "DOWNED uses woozy concentric ring eyes")
	check(v1._halo.visible == true, "DOWNED activates orbiting halo")
	check(v1._torso.scale.y < 0.75, "DOWNED applies collapsed belly squash on ice")
	check(v1._front_flipper.rotation > 1.0, "DOWNED flippers sprawl limp on ice")

	# 6. Revived triggers REVIVE get-up sequence
	var node_count_before: int = v1.get_child_count() + v1._pivot.get_child_count()
	p1.health.heal(50) # In this engine, health.heal() does not revive dead player, let's use health.revived emission or check Health class
	# Let's check how Health revives:
	if not p1.health.is_alive():
		# Emit revived or set alive
		p1.health.current = 50.0
		p1.health.revived.emit(50.0)

	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.REVIVE, "revived signal enters REVIVE get-up state")
	check(v1._halo.visible == false, "REVIVE hides halo")
	check(v1._eyes.texture == CharacterVisual.TEX_EYES_ALERT, "REVIVE restores alert eyes")

	# Advance revive timer to completion
	v1._process_player(0.40)
	check(v1.current_state == CharacterVisual.State.IDLE, "REVIVE completion settles in IDLE")

	# 7. Repeated die/revive cycles do not leak child nodes
	for cycle in range(5):
		p1.health.died.emit(DamageEvent.new(1000))
		v1._process_player(0.016)
		p1.health.revived.emit(100.0)
		v1._process_player(0.40)
	var node_count_after: int = v1.get_child_count() + v1._pivot.get_child_count()
	check(node_count_before == node_count_after, "repeated die/revive cycles do not leak nodes")

	# 8. Multi-player isolation (P1 and P2 have independent states and tints)
	check(v1.current_state == CharacterVisual.State.IDLE, "P1 is IDLE")
	p2.velocity = Vector2(100, 0)
	v2._process_player(0.016)
	check(v2.current_state == CharacterVisual.State.WADDLE, "P2 is WADDLE independently")
	check(v1.current_state == CharacterVisual.State.IDLE, "P1 remains IDLE while P2 waddles")

	check(v1._scarf_wrap.modulate != v2._scarf_wrap.modulate, "P1 and P2 have distinct team tints")

	# 9. Presentation does NOT alter collision shape or gameplay physics values
	var shape: CircleShape2D = (p1.get_node("CollisionShape2D") as CollisionShape2D).shape as CircleShape2D
	check(shape != null and shape.radius == 16.0, "collision shape radius preserved at 16.0")
	check(p1.speed == 220.0, "player movement speed preserved at 220.0")
	check(p1.dash.burst_speed == 680.0, "dash burst speed preserved at 680.0")
	check(p1.dash.duration == 0.16, "dash duration preserved at 0.16")

	arena.free()

	print("PENGUIN PRESENTATION TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
