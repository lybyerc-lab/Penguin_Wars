extends SceneTree
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func touch(index: int, point: Vector2, pressed: bool, canceled: bool = false) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	event.canceled = canceled
	return event

func _run() -> void:
	var stats := PlayerStats.new()
	stats.armor = 10
	check(is_equal_approx(stats.damage_received(30, 1), 20), "armor reduces damage with diminishing returns")
	stats.dodge_chance = 100
	check(stats.damage_received(30, 0.59) == 0 and stats.damage_received(30, 0.61) > 0, "dodge caps at sixty percent")
	stats.melee_damage = 3
	stats.damage_percent = 20
	stats.critical_chance = 100
	check(is_equal_approx(stats.weapon_damage(10, true, 0.5), 23.4), "flat melee, percent damage and critical multiply in order")
	check(is_equal_approx(stats.weapon_damage(10, false, 0.5), 18), "melee bonus does not affect ranged weapon")
	stats.attack_speed = 100
	check(stats.cooldown(0.8) == 0.4, "attack speed changes real cooldown")
	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	arena.mobile_preview = true
	root.add_child(arena)
	await process_frame
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	await physics_frame
	check(arena.party.members().size() == 1, "mobile defaults to one local player")
	var player: PenguinPlayer = arena.party.members()[0]
	var hud: MobileHUD = arena.get_node("MobileHUD")
	var controls: TouchControls = hud.controls
	var center: Vector2 = controls.stick_center()
	controls._input(touch(0, center + Vector2(60, 0), true))
	check(player.input_source.movement().x > 0.7, "touch movement reaches input adapter")
	controls._input(touch(1, controls.dash_center(), true))
	check(player.input_source.dash_requested(), "second finger triggers dash")
	check(not player.input_source.dash_requested(), "touch dash is a one-shot command")
	check(player.input_source.movement().x > 0.7, "dash does not release movement finger")
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = center + Vector2(0, -120)
	controls._input(drag)
	check(player.input_source.movement() == Vector2.UP, "drag direction normalized")
	controls._input(touch(0, center, false, true))
	check(player.input_source.movement() == Vector2.ZERO, "canceled touch releases movement")
	controls._input(touch(2, center + Vector2(60, 0), true))
	controls._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(player.input_source.movement() == Vector2.ZERO, "focus loss clears touch state")
	hud.open_sheet()
	check(paused, "solo mobile character sheet pauses combat")
	check(not controls.enabled, "character sheet disables touch combat zones")
	hud._sheet.queue_free()
	await process_frame
	check(controls.enabled, "closing sheet restores touch controls")
	check(not paused, "closing sheet resumes combat")
	player.apply_upgrade(load("res://resources/upgrades/vitality.tres"))
	check(player.health.maximum == 120 and player.health.current == 120, "vitality increases and heals max HP")
	player.apply_upgrade(load("res://resources/upgrades/armor.tres"))
	player.health.take_damage(DamageEvent.new(22))
	check(player.health.current == 100, "armor connected to health damage interface")
	player.apply_upgrade(load("res://resources/upgrades/regeneration.tres"))
	player._physics_process(1.0)
	check(player.health.current == 101, "regeneration heals over time")
	player.stats.critical_chance = 100
	var enemy: ArenaEnemy = load("res://scenes/actors/enemy.tscn").instantiate()
	enemy.party = arena.party
	enemy.position = player.position + Vector2(80, 0)
	arena.get_node("Actors").add_child(enemy)
	enemy.set_physics_process(false)
	player.weapon._physics_process(2.0)
	check(enemy.health.current == 7, "critical chance changes actual weapon damage")
	player.apply_upgrade(load("res://resources/upgrades/gathering.tres"))
	var pickup: RunPickup = arena.get_node("Loot").spawn_pickup(player.global_position + Vector2(45, 0), RunPickup.Kind.SNOWFLAKE, 2)
	pickup._physics_process(0.4)
	check(pickup.claimed, "pickup stat increases collection radius")
	player.health.take_damage(DamageEvent.new(10000))
	player._physics_process(1)
	check(player.health.current == 0, "regeneration cannot revive dead player")
	arena.free()
	print("STATS & MOBILE TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
