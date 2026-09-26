extends SceneTree
## Fast mobile-entry smoke: shipped scene, full-display framing, context action,
## service UI, and the exact phone blockers found during Township review.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _service(run: Node2D, kind: TownService.Kind) -> TownService:
	for service: TownService in run.services():
		if service.kind == kind:
			return service
	return null

func _run() -> void:
	var configured_main: String = String(ProjectSettings.get_setting("application/run/main_scene", ""))
	check(configured_main == "res://scenes/run/expedition.tscn", "shipping main scene is the expedition")

	var previous_size: Vector2i = root.size
	root.size = Vector2i(1536, 720)

	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	run.mobile_preview = true
	root.add_child(run)
	for frame: int in range(6):
		await process_frame

	check(run.party.members().size() == 1, "mobile expedition starts with one local player")
	check(run.session != null and run.session.mobile, "mobile flag reaches RunSession")
	check(run.encounter.auto_advance, "mobile cave waves do not require an unavailable Ready key")
	check(run.has_node("MobileControls"), "mobile expedition creates touch controls")
	check(run._mobile_controls != null, "touch controls are wired")
	check(run._mobile_controls.input_source == run.party.members()[0].input_source, "touch controls drive P1")

	var camera := run.get_node("Camera") as PartyCamera
	camera._process(10.0)
	check(camera.mobile_layout, "camera uses mobile layout")
	check(camera.follow_party, "Township keeps follow-camera behavior")
	check(camera.zoom.x > 0.85, "wide-phone world framing uses most of the display")
	check(camera.offset.length() < 1.0, "mobile HUD overlays world instead of vertically shifting gameplay")

	var player: PenguinPlayer = run.party.members()[0]
	var rack_controller: WeaponController = player.weapon_rack.controller_at(0)
	check(rack_controller != null and rack_controller.z_index == 0, "weapon stays in its owner's y-sort instead of floating above roofs")

	var fisher := _service(run, TownService.Kind.SHOP)
	check(fisher != null and fisher.position == Vector2(505, 72), "Fisher service pad sits in front of the stall")
	player.position = fisher.position
	run._process(0.0)
	run.overlay._process(0.0)
	check(run._mobile_controls.context_action_label == "SHOP", "service pad replaces Dash with SHOP")
	run._on_mobile_context_action()
	run.overlay._process(0.0)
	check(run.overlay.mobile_service_open(1), "SHOP action opens the mobile service panel")
	var fisher_card: Dictionary = run.overlay._cards.get(1, {})
	check(not fisher_card.is_empty() and fisher_card["panel"].visible, "mobile service panel is visible after SHOP")
	var buttons: Array = fisher_card.get("buttons", [])
	check(buttons.size() == 3 and (buttons[0] as Button).visible, "mobile shop exposes touchable offers")

	var hall := _service(run, TownService.Kind.TOWN_HALL)
	player.position = hall.position
	run._process(0.0)
	run.overlay._process(0.0)
	check(run._mobile_controls.context_action_label == "TALK", "Town Hall replaces Dash with TALK")

	var township := run.get_node("Places/TownshipV01") as TownshipV01
	check(township.has_node("BellCollision"), "bell has collision")
	check(township.has_node("SlideDeckCollision"), "slide launch deck has collision")
	check(township.has_node("WorkshopWestAnnexCollision"), "Workshop west annex has collision")
	check(township.has_node("HomeACollision"), "Nurse hut uses the full approved footprint")
	check(township.has_node("FishersStallCollision"), "Fisher stall uses full-footprint collision")
	var slide_collision := township.get_node("SnowSlide/CollisionShape2D") as CollisionShape2D
	check(slide_collision != null and slide_collision.position.y > 0.0, "slide active area starts south of the raised deck")

	run.free()
	root.size = previous_size
	print("MOBILE EXPEDITION TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
