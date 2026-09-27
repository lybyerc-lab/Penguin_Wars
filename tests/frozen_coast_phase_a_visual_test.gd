extends SceneTree
## Focused production-art adapter smoke. Gameplay tests remain the authority for
## route/combat behavior; this verifies the approved environment package wires in.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var places := Node2D.new()
	places.name = "Places"
	host.add_child(places)
	var actors := Node2D.new()
	actors.name = "Actors"
	host.add_child(actors)
	var visual := FrozenCoastPhaseAVisual.build(places, actors)
	await process_frame

	check(visual.get_node_or_null("BackgroundPlate") != null, "production background plate loads")
	check(visual.foreground_layer_count() == 29, "all 29 approved foreground layers are created")
	check(visual.soft_zone_count() == 8, "all 8 authored soft drift zones are retained")
	check(visual.hard_body_count() >= 12, "production hard collision bodies are created")

	for layer_name: StringName in [&"rim_passw", &"rim_passe_w", &"rim_passe_m", &"rim_passe_e"]:
		var root_node := visual.layer_root(layer_name)
		check(root_node != null, "%s rim layer exists" % layer_name)
		if root_node != null:
			var sprite := root_node.get_node_or_null("Sprite") as Sprite2D
			check(sprite != null and is_equal_approx(sprite.modulate.a, 0.45), "%s uses approved 45%% opacity" % layer_name)

	var wedge := visual.get_node_or_null("RibSouthWedgeFill") as StaticBody2D
	check(wedge != null and wedge.is_in_group(&"tuskbull_no_stun"), "south rib wedge is a blocker without hard-impact stun")
	var pillar := visual.get_node_or_null("PillarA") as StaticBody2D
	check(pillar != null and not pillar.is_in_group(&"tuskbull_no_stun"), "Pillar A remains a Tuskbull hard-impact object")

	var charge := ChargeBehavior.new()
	charge.crash_on_world_collision = true
	charge.state = ChargeBehavior.State.CHARGE
	charge.remaining = 0.5
	charge.on_world_collision(false)
	check(charge.state == ChargeBehavior.State.CHARGE, "no-stun blocker leaves a committed Tuskbull charge active")
	charge.on_world_collision(true)
	check(charge.state == ChargeBehavior.State.RECOVER and is_equal_approx(charge.remaining, charge.crash_recovery_time), "hard impact enters Tuskbull crash recovery")

	host.free()
	print("FROZEN COAST PHASE A VISUAL TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
