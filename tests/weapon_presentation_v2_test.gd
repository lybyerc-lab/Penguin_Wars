extends SceneTree

var failures: int = 0
const SPEAR: WeaponDefinition = preload("res://resources/weapons/fish_spear.tres")
const SLINGSHOT: WeaponDefinition = preload("res://resources/weapons/icicle_slingshot.tres")
const BOMB: WeaponDefinition = preload("res://resources/weapons/snowbomb.tres")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena := load("res://scenes/arena/test_arena.tscn").instantiate() as Node2D
	root.add_child(arena)
	await process_frame
	var player: PenguinPlayer = arena.party.members()[0]
	player.configure_weapon_loadout([SPEAR, SLINGSHOT, BOMB, SPEAR, SLINGSHOT, BOMB])
	var rack: WeaponRack = player.weapon_rack
	await process_frame
	for slot: int in range(6):
		var visual := rack.controller_at(slot).get_node("Visual") as WeaponVisual
		check(rack.hand_of(slot) == &"" and visual._back.visible and not visual._front.visible, "idle weapon %d is stowed on the back layer" % slot)
	for slot: int in range(6):
		rack.request_hand(slot)
	var held_count: int = 0
	for slot: int in range(6):
		if rack.hand_of(slot) != &"": held_count += 1
	check(held_count == 2, "the rack grants at most two presentation hands at one frame")
	rack.clear_hands()
	var spear_visual := rack.controller_at(0).get_node("Visual") as WeaponVisual
	var spear_controller := rack.controller_at(0)
	spear_controller._flash = 0.1
	spear_controller._flash_duration = 0.18
	spear_controller.aim_angle = 0.0
	spear_visual._process(0.01)
	check(spear_visual._front.visible and not spear_visual._back.visible, "front hand renders above the body for a forward aim")
	spear_controller.aim_angle = -PI * 0.75
	spear_visual._process(0.01)
	check(spear_visual._back.visible and not spear_visual._front.visible, "high/back aim renders below the body")
	var bomb_controller := rack.controller_at(2)
	var bomb_visual := bomb_controller.get_node("Visual") as WeaponVisual
	bomb_controller._pending_area = true
	bomb_controller._pending_area_duration = 1.0
	bomb_controller._pending_area_remaining = 0.5
	bomb_visual._process(0.01)
	check(not bomb_visual._back.visible and not bomb_visual._front.visible, "snowbomb art is hidden while its projectile is in flight")
	check(SPEAR.held_grip_texel == Vector2(81, 30) and (preload("res://resources/weapons/fish_spear_iv.tres") as WeaponDefinition).held_grip_texel == Vector2(81, 30), "all spear tiers carry the authored grip point")
	check(SLINGSHOT.held_base_rotation > 1.5 and SLINGSHOT.presentation_family == &"hip", "slingshot uses rotation without vertical flipping")
	arena.free()
	print("WEAPON PRESENTATION V2 TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
