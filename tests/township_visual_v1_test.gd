extends SceneTree
## Focused checks for the baked Township V1 presentation adapter, Nurse
## approach correction, and player-neutral service camera focus.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func settle(frames: int = 5) -> void:
	for frame: int in range(frames):
		await physics_frame

func service_of(run: Node2D, kind: TownService.Kind) -> TownService:
	for service: TownService in run.services():
		if service.kind == kind:
			return service
	return null

func has_node3d(node: Node) -> bool:
	if node is Node3D:
		return true
	for child: Node in node.get_children():
		if has_node3d(child):
			return true
	return false

func point_hits_rect_body(body: StaticBody2D, point: Vector2) -> bool:
	var collision := body.get_child(0) as CollisionShape2D
	var shape := collision.shape as RectangleShape2D
	return Rect2(collision.position - shape.size * 0.5, shape.size).has_point(point)

func verify_fresh_focus(activator_index: int) -> void:
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	run.player_count = 4
	root.add_child(run)
	await settle()
	var hall := service_of(run, TownService.Kind.TOWN_HALL)
	var players: Array[PenguinPlayer] = run.party.members()
	var nearby := [Vector2(145, 0), Vector2(180, 15), Vector2(210, -15), Vector2(245, 5)]
	for index: int in range(players.size()):
		players[index].position = hall.position + nearby[index]
	players[activator_index].position = hall.position
	run.call("_process", 0.0)
	check((run.get_node("Camera") as PartyCamera).focus_active, "P%d activates building focus first in a fresh scene" % (activator_index + 1))
	run.free()
	await process_frame

func _run() -> void:
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	run.player_count = 4
	root.add_child(run)
	await settle(8)

	var township := run.get_node("Places/TownshipV01") as TownshipV01
	var visual := run.get_node("Places/TownshipVisualV1") as TownshipVisualV1
	check(township != null and visual != null, "Township gameplay and production visual nodes load together")
	check(not has_node3d(run), "Township integration preserves the Node2D gameplay architecture")
	check((run.get_node("Actors") as Node2D).y_sort_enabled, "Township enables existing actor-layer y sorting for occlusion")
	check(visual.get_node_or_null("BackgroundPlate") is Sprite2D, "approved environment background plate is loaded")
	var background := visual.get_node("BackgroundPlate") as Sprite2D
	check(background.texture.get_width() == 3584 and background.texture.get_height() == 2016, "background stays within a 4096-pixel mobile texture edge")

	var occluders: Array[Node] = run.get_node("Actors").get_children().filter(func(node: Node) -> bool:
		return node.has_meta(&"township_visual_layer")
	)
	check(occluders.size() == TownshipVisualV1.SORT_BASELINES.size(), "all ten bounded foreground occlusion layers load")

	var nurse := service_of(run, TownService.Kind.NURSE)
	check(nurse.position == Vector2(-644, 670), "Nurse pad uses the approved south-gable position")
	check(run.services().size() == 4, "Lodge remains visual-only with no invented service")
	check(not township.has_node("HomeACollision"), "solid Nurse rectangle was replaced")
	var notch_point := Vector2(-565, 585)
	check(not point_hits_rect_body(township.get_node("HomeACollisionNorth"), notch_point), "Nurse passage clears the north collision box")
	check(not point_hits_rect_body(township.get_node("HomeACollisionWest"), notch_point), "Nurse passage clears the west collision box")

	var hall := service_of(run, TownService.Kind.TOWN_HALL)
	var players: Array[PenguinPlayer] = run.party.members()
	players[1].position = hall.position
	players[0].position = hall.position + Vector2(145, 0)
	players[2].position = hall.position + Vector2(180, 15)
	players[3].position = hall.position + Vector2(210, -15)
	run.call("_process", 0.0)
	check((run.get_node("Camera") as PartyCamera).focus_active, "P2 can trigger focus before P1 in the loaded four-player run")
	players[0].position = hall.position + Vector2(TownService.CAMERA_GROUP_RADIUS + 90, 0)
	run.call("_process", 0.0)
	check(not (run.get_node("Camera") as PartyCamera).focus_active, "spread-party camera suppression remains active")

	run.free()
	await process_frame
	for activator_index: int in [1, 2, 3]:
		await verify_fresh_focus(activator_index)

	print("TOWNSHIP VISUAL V1 TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
