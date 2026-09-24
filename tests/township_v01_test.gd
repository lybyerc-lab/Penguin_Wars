extends SceneTree
## Focused playable-blockout checks for Township V0.1.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	run.player_count = 4
	root.add_child(run)
	await physics_frame
	await physics_frame

	var township := run.get_node_or_null("Places/TownshipV01") as TownshipV01
	check(township != null, "Township V0.1 runtime layout is present")
	check(run.room.bounds == TownshipV01.WORLD_BOUNDS, "town room uses the playable Township bounds")
	check(run.get_node("Camera").follow_party, "large town camera follows the party")
	check(not run.get_node("Backdrop").visible, "legacy single-screen arena backdrop is hidden in town")
	check(run.party.members().size() == 4, "four players spawn in the same town architecture")
	check(run.services().size() == 4, "existing town services remain available at landmark doors")
	check(run.gates().size() == 1, "Expedition remains the sole town travel authority")
	check(run.gates()[0].position == TownshipV01.DEPARTURE_BOUNDARY, "travel threshold is at the Frozen Coast boundary")

	if township != null:
		check(township.get_node_or_null("GreatHallCollision") is StaticBody2D, "Great Hall has simple collision")
		check(township.get_node_or_null("MarketCounterCollision") is StaticBody2D, "market counter has simple collision")
		check(township.get_node_or_null("MarketPostCollision") == null, "slender market posts do not create snag collisions")
		var slide := township.get_node_or_null("SnowSlide") as TownshipSnowSlide
		check(slide != null, "snow slide has a physical runtime zone")
		if slide != null:
			var rider: PenguinPlayer = run.party.members()[0]
			rider.position = TownshipV01.SLIDE_CENTER
			rider.input_source.touch_movement = Vector2.ZERO
			var before: Vector2 = rider.position
			for frame: int in range(12):
				await physics_frame
			check(rider.position.y > before.y + 8.0, "snow slide pushes a penguin toward its runout")

	for player: PenguinPlayer in run.party.members():
		check(player.arena_bounds == TownshipV01.WORLD_BOUNDS, "P%d receives the town movement bounds" % player.identity.player_id)

	run.free()
	print("TOWNSHIP V0.1 TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
