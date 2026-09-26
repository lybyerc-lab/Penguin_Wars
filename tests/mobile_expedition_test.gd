extends SceneTree
## Fast mobile-entry smoke: the shipped main scene is Expedition, Android-style
## setup uses one local player + touch controls, and the world is not shrunk
## into a center strip by HUD reservations.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

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
	check(run.has_node("MobileControls"), "mobile expedition creates touch controls")
	check(run._mobile_controls != null, "touch controls are wired")
	check(run._mobile_controls.input_source == run.party.members()[0].input_source, "touch controls drive P1")

	var camera := run.get_node("Camera") as PartyCamera
	camera._process(10.0)
	check(camera.mobile_layout, "camera uses mobile layout")
	check(camera.follow_party, "Township keeps follow-camera behavior")
	check(camera.zoom.x > 0.85, "wide-phone world framing uses most of the display")
	check(camera.offset.length() < 1.0, "mobile HUD overlays world instead of vertically shifting gameplay")

	run.free()
	root.size = previous_size
	print("MOBILE EXPEDITION TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
