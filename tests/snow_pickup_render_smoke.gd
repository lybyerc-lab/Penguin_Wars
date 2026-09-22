extends SceneTree
## Uses the real renderer; do not run with --headless.
## Captures Snow pickup fixtures:
## 1. docs/snow-pickup-values.png (Small, Chunky, Big, Jackpot tiers + Health pickup)
## 2. docs/snow-pickup-collect.png (Pop arrival, magnet suction, and collection puff FX)

func _initialize() -> void:
	call_deferred("_run")

func shot(path: String) -> Error:
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	return img.save_png(path)

func settle(frames: int) -> void:
	for frame: int in range(frames):
		await process_frame

func _run() -> void:
	print("Starting Snow Pickup Render Smoke...")

	# --- FIXTURE 1: docs/snow-pickup-values.png ---
	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	root.add_child(arena)
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	await settle(60)

	var loot: ArenaLoot = arena.get_node("Loot")
	var players: Array[PenguinPlayer] = arena.party.members()
	players[0].position = Vector2(-220, 20)
	players[1].position = Vector2(220, 20)
	players[0].dash.facing = Vector2.RIGHT
	players[1].dash.facing = Vector2.LEFT

	# Position the 4 snow value tiers horizontally across the arena center with generous spacing
	# SMALL (amount 1)
	var p_small: RunPickup = loot.spawn_pickup(Vector2(-120, 10), RunPickup.Kind.SNOWFLAKE, 1)
	p_small.shape_variant = 0
	p_small._age = 1.0

	# CHUNKY (amount 4)
	var p_chunky: RunPickup = loot.spawn_pickup(Vector2(-40, 10), RunPickup.Kind.SNOWFLAKE, 4)
	p_chunky.shape_variant = 1
	p_chunky._age = 1.0

	# BIG (amount 8)
	var p_big: RunPickup = loot.spawn_pickup(Vector2(40, 10), RunPickup.Kind.SNOWFLAKE, 8)
	p_big.shape_variant = 0
	p_big._age = 1.0

	# JACKPOT (amount 12)
	var p_jackpot: RunPickup = loot.spawn_pickup(Vector2(120, 10), RunPickup.Kind.SNOWFLAKE, 12)
	p_jackpot.shape_variant = 0
	p_jackpot._age = 1.0

	# HEALTH PICKUP nearby for visual contrast
	var p_health: RunPickup = loot.spawn_pickup(Vector2(0, 80), RunPickup.Kind.HEALTH, 25)
	p_health._age = 1.0

	await settle(15)
	var res_val: Error = await shot("res://docs/snow-pickup-values.png")
	print("CAPTURE values: ", "PASS" if res_val == OK else "FAIL")

	arena.queue_free()
	await settle(10)

	# --- FIXTURE 2: docs/snow-pickup-collect.png ---
	var arena2: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	arena2.player_count = 1
	root.add_child(arena2)
	for node: Node in arena2.find_children("*", "", true, false):
		node.set_physics_process(false)
	await settle(60)

	var loot2: ArenaLoot = arena2.get_node("Loot")
	var p2: Array[PenguinPlayer] = arena2.party.members()
	p2[0].position = Vector2(-70, 20)
	p2[0].dash.facing = Vector2.RIGHT

	# 1. Pickup mid-suction traveling towards player
	var p_suck: RunPickup = loot2.spawn_pickup(Vector2(0, 20), RunPickup.Kind.SNOWFLAKE, 4)
	p_suck._age = 0.5
	p_suck._is_magnetized = true
	p_suck._target_player = p2[0]
	p_suck._magnet_speed = 450.0

	# 2. Pickup at the exact moment of collection pop (expanding puff + scatter flecks)
	var p_pop: RunPickup = loot2.spawn_pickup(Vector2(-70, 10), RunPickup.Kind.SNOWFLAKE, 3)
	p_pop.claimed = true
	p_pop._collecting = true
	p_pop._collection_timer = 0.05

	# 3. Fresh drop in pop arrival arc (high in the air)
	var p_midair: RunPickup = loot2.spawn_pickup(Vector2(80, -20), RunPickup.Kind.SNOWFLAKE, 6)
	p_midair._age = 0.08

	# 4. Settled chunk sitting on ice
	var p_ground: RunPickup = loot2.spawn_pickup(Vector2(140, 40), RunPickup.Kind.SNOWFLAKE, 2)
	p_ground._age = 1.2

	# 5. Jackpot chunk gleaming in the field
	var p_jp: RunPickup = loot2.spawn_pickup(Vector2(30, 80), RunPickup.Kind.SNOWFLAKE, 15)
	p_jp._age = 1.0

	await settle(15)
	var res_col: Error = await shot("res://docs/snow-pickup-collect.png")
	print("CAPTURE collect: ", "PASS" if res_col == OK else "FAIL")

	arena2.queue_free()
	await settle(5)

	var overall_pass: bool = (res_val == OK and res_col == OK)
	print("SNOW PICKUP RENDER SMOKE: ", "PASS" if overall_pass else "FAIL")
	quit(0 if overall_pass else 1)
