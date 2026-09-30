extends SceneTree
## Focused production-art adapter smoke. Gameplay tests remain the authority for
## route/combat behavior; this verifies the approved environment package wires in.

var failures: int = 0
const TUSKBULL: PackedScene = preload("res://scenes/actors/tuskbull.tscn")

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
	var drift_0 := visual.get_node_or_null("Soft_Drift0") as Area2D
	check(drift_0 != null and drift_0.monitoring and drift_0.collision_mask == 4, "soft drifts monitor the enemy physics layer without becoming solid")
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

	# The authored areas slow only an opted-in Tuskbull. They do not alter the
	# committed state or invoke the existing hard-impact recovery path.
	var soft_zone := drift_0
	check(soft_zone != null, "an authored soft drift is available for runtime verification")

	var bull := TUSKBULL.instantiate() as ArenaEnemy
	actors.add_child(bull)
	bull.set_physics_process(false)
	var charge := bull.behavior as ChargeBehavior
	var target := PenguinPlayer.new()
	target.position = Vector2.RIGHT * 1000.0
	bull.position = Vector2.ZERO
	charge.state = ChargeBehavior.State.CHARGE
	charge.remaining = 2.0
	charge.direction = Vector2.RIGHT
	var normal_velocity := charge.movement(bull, target, 0.01)
	check(is_equal_approx(normal_velocity.length(), charge.charge_speed), "normal Tuskbull charge uses normal speed")

	if soft_zone != null:
		var polygon := soft_zone.get_child(0) as CollisionPolygon2D
		var triangles := Geometry2D.triangulate_polygon(polygon.polygon)
		check(triangles.size() >= 3, "authored soft drift polygon has a usable interior")
		var zone_center := (
			polygon.polygon[triangles[0]]
			+ polygon.polygon[triangles[1]]
			+ polygon.polygon[triangles[2]]
		) / 3.0
		bull.position = zone_center
		await physics_frame
		await physics_frame
		charge.state = ChargeBehavior.State.CHARGE
		charge.remaining = 2.0
		charge.direction = Vector2.RIGHT
		var drift_velocity := charge.movement(bull, target, 0.01)
		check(charge.soft_charge_active(), "entering an authored soft drift is detected")
		check(is_equal_approx(drift_velocity.length(), charge.charge_speed * charge.soft_charge_speed_multiplier), "soft drift applies the provisional Tuskbull slowdown")
		check(charge.state == ChargeBehavior.State.CHARGE, "soft drift leaves the Tuskbull in CHARGE")
		check(not is_equal_approx(charge.remaining, charge.crash_recovery_time), "soft drift never triggers crash recovery")

		bull.position = Vector2.ZERO
		await physics_frame
		await physics_frame
		charge.state = ChargeBehavior.State.CHARGE
		charge.remaining = 2.0
		charge.direction = Vector2.RIGHT
		var restored_velocity := charge.movement(bull, target, 0.01)
		check(not charge.soft_charge_active(), "leaving authored soft drift clears the slowdown")
		check(is_equal_approx(restored_velocity.length(), charge.charge_speed), "leaving soft drift restores normal charge speed")

	charge.state = ChargeBehavior.State.CHARGE
	charge.remaining = 0.5
	charge.direction = Vector2.RIGHT
	charge.on_world_collision(false)
	check(charge.state == ChargeBehavior.State.CHARGE, "no-stun blocker leaves a committed Tuskbull charge active")
	charge.on_world_collision(true)
	check(charge.state == ChargeBehavior.State.RECOVER and is_equal_approx(charge.remaining, charge.crash_recovery_time), "hard impact enters Tuskbull crash recovery")
	target.free()

	host.free()
	print("FROZEN COAST PHASE A VISUAL TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
