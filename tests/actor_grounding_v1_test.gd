extends SceneTree
## Focused presentation-only contract for Actor Grounding V1.

var failures: int = 0
const ARENA: PackedScene = preload("res://scenes/arena/test_arena.tscn")
const ROLLY: PackedScene = preload("res://scenes/actors/rolly.tscn")
const FISH_SPEAR: WeaponDefinition = preload("res://resources/weapons/fish_spear.tres")
const SLINGSHOT: WeaponDefinition = preload("res://resources/weapons/icicle_slingshot.tres")
const SNOWBOMB: WeaponDefinition = preload("res://resources/weapons/snowbomb.tres")
const DRIFTFIELD: RoomDefinition = preload("res://resources/rooms/driftfield_phase_a.tres")

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func disable_actor_physics(root_node: Node) -> void:
	for node: Node in root_node.find_children("*", "", true, false):
		if node is CharacterBody2D:
			node.set_physics_process(false)

func _run() -> void:
	# Region adapters publish the exact sun contract used by actor cast shadows.
	var run := load("res://scenes/run/expedition.tscn").instantiate() as Node2D
	root.add_child(run)
	await process_frame
	var town_sun: Dictionary = get_meta(CharacterVisual.ACTOR_SUN_META, {})
	check(town_sun.get("region", &"") == &"township", "Township publishes its actor sun region")
	check(is_equal_approx(float(town_sun.get("angle_deg", 0.0)), -38.5), "Township publishes the locked cast angle")
	check(is_equal_approx(float(town_sun.get("len_per_m", 0.0)), 103.5), "Township publishes the locked cast length scale")
	run._enter_room(DRIFTFIELD)
	await process_frame
	var coast_sun: Dictionary = get_meta(CharacterVisual.ACTOR_SUN_META, {})
	check(coast_sun.get("region", &"") == &"frozen_coast", "Frozen Coast publishes its actor sun region")
	check(is_equal_approx(float(coast_sun.get("angle_deg", 0.0)), -51.6), "Frozen Coast publishes the locked cast angle")
	check(is_equal_approx(float(coast_sun.get("len_per_m", 0.0)), 139.2), "Frozen Coast publishes the locked cast length scale")
	run.free()

	var arena := ARENA.instantiate() as Node2D
	root.add_child(arena)
	await process_frame
	disable_actor_physics(arena)
	set_meta(CharacterVisual.ACTOR_SUN_META, CharacterVisual.DEFAULT_ACTOR_SUN)

	var player: PenguinPlayer = arena.party.members()[0]
	var visual := player.get_node("CharacterVisual") as CharacterVisual
	var collision := player.get_node("CollisionShape2D") as CollisionShape2D
	var body_shape := collision.shape as CircleShape2D
	var player_root_before: Vector2 = player.global_position
	var collision_before: Vector2 = collision.global_position
	var speed_before: float = player.speed
	var dash_speed_before: float = player.dash.burst_speed
	var dash_duration_before: float = player.dash.duration

	check(visual.get_node_or_null("GroundShadow/CastShadow") == visual._cast_shadow, "player has a cast-shadow sprite")
	check(visual.get_node_or_null("GroundShadow/ContactShadow") == visual._contact_shadow, "player has a contact-shadow sprite")
	check(visual.get_node_or_null("GroundShadow/TeamRing") == visual._team_ring, "smaller team identity ring remains present")
	check(visual._ground_shadow.z_index == -2 and visual._pivot.z_index == 0, "only the grounding layer offsets draw depth below the body")
	check(visual._ground_shadow.get_child(0) == visual._team_ring and visual._ground_shadow.get_child(1) == visual._cast_shadow and visual._ground_shadow.get_child(2) == visual._contact_shadow, "ground order is indicator then cast/contact shadow then character")
	check(visual._team_ring.width == 1.5 and visual._team_ring.points.size() == 32, "team ring uses the quiet 42 by 15 presentation")
	check(visual.animated_sprite.modulate.is_equal_approx(CharacterVisual.AMBIENT_TINT), "player body receives the restrained cool ambient tint")
	check(visual.scarf_sprite.modulate != visual.animated_sprite.modulate, "scarf tint remains independent from body tint")

	player.velocity = Vector2(220.0, 0.0)
	visual._process_player(1.0 / 60.0)
	var right_rotation: float = visual._cast_shadow.rotation
	var right_shadow_x: float = visual._ground_shadow.position.x
	player.velocity = Vector2(-220.0, 0.0)
	visual._process_player(1.0 / 60.0)
	check(is_equal_approx(visual._cast_shadow.rotation, right_rotation), "cast-shadow sun direction does not mirror when player facing flips")
	check(signf(visual._ground_shadow.position.x) != signf(right_shadow_x), "contact placement mirrors with player facing")
	check(player.global_position == player_root_before and collision.global_position == collision_before, "grounding motion never moves the player root or collision")
	check(is_equal_approx(body_shape.radius, 16.0) and player.speed == speed_before, "grounding leaves player collision radius and speed unchanged")

	player.dash.direction = Vector2.RIGHT
	player.dash.remaining = player.dash.duration
	player.velocity = Vector2(player.dash.burst_speed, 0.0)
	visual._process_player(1.0 / 60.0)
	check(player.velocity == Vector2(dash_speed_before, 0.0), "visual dash response does not modify dash velocity")
	check(player.dash.burst_speed == dash_speed_before and player.dash.duration == dash_duration_before, "dash mechanics remain unchanged")
	check(CharacterVisual.WADDLE_CYCLE_DISTANCE == 108.0, "Waddle cadence uses the approved 108 px candidate")

	# Combat effects share the body-centred hand origin while stowed weapon art
	# uses its authored grip and the rack/controller mechanics stay unchanged.
	player.configure_weapon_loadout([FISH_SPEAR, SLINGSHOT, SNOWBOMB])
	var rack: WeaponRack = player.weapon_rack
	var spear: WeaponController = rack.controller_at(0)
	var sling: WeaponController = rack.controller_at(1)
	var bomb: WeaponController = rack.controller_at(2)
	visual._frame_sway_x = 0.0
	visual._frame_lift = 0.0
	visual._facing_direction = 1.0
	check(spear.presentation_origin(0.0) == Vector2(15.0, -17.0), "Fish Spear combat effect uses the shared body-centred hand origin")
	check(sling.presentation_origin(0.0) == spear.presentation_origin(0.0) and bomb.presentation_origin(0.0) == spear.presentation_origin(0.0), "all combat effects use the same body-centred origin")
	var spear_visual := spear.get_node("Visual") as WeaponVisual
	spear_visual._process(0.0)
	check(spear_visual._back.offset == Vector2(39.0, -6.0), "Fish Spear authored grip, rather than texture centre, sits on the socket")
	check(spear_visual._back.modulate.is_equal_approx(WeaponVisual.AMBIENT_TINT), "stowed weapon receives actor ambient tint")
	check(spear.z_index == 0 and spear_visual.z_index == 0, "weapon presentation adds no z-index override")
	check(rack.get_index() < visual.get_index() and visual.get_index() < player.get_node("WeaponFront").get_index(), "back/body/front scene order remains authoritative")

	var target := ROLLY.instantiate() as ArenaEnemy
	target.party = arena.party
	target.position = player.position + Vector2(40.0, 0.0)
	arena.get_node("Actors").add_child(target)
	await process_frame
	target.set_physics_process(false)
	var target_health_before: float = target.health.current
	spear._remaining = 0.0
	spear._phase_remaining = 0.0
	spear._physics_process(0.1)
	check(target.health.current < target_health_before and spear._remaining > 0.0, "new weapon origin does not alter controller firing or damage")

	# Enemy body re-anchors visually while all gameplay authority stays fixed.
	var enemy := ROLLY.instantiate() as ArenaEnemy
	enemy.party = arena.party
	enemy.position = Vector2(160.0, 80.0)
	arena.get_node("Actors").add_child(enemy)
	await process_frame
	enemy.set_physics_process(false)
	var enemy_visual := enemy.get_node("CharacterVisual") as CharacterVisual
	var enemy_collision := enemy.get_node("CollisionShape2D") as CollisionShape2D
	var enemy_root_before: Vector2 = enemy.global_position
	var enemy_collision_before: Transform2D = enemy_collision.global_transform
	var contact_before: float = enemy.contact_radius
	var hit_before: float = enemy.hit_radius
	enemy.velocity = Vector2.ZERO
	enemy_visual._process_enemy(0.0)
	check(enemy_visual.enemy_art_id == &"rolly" and enemy_visual._enemy_anim != null, "Rolly uses the production enemy presentation")
	check(enemy_visual._enemy_anim.position == Vector2.ZERO and enemy_visual._enemy_anim.rotation == 0.0, "production enemy art stays on the authored ground anchor without procedural bob")
	check(enemy_visual.get_node_or_null("GroundShadow/CastShadow") != null and enemy_visual.get_node_or_null("GroundShadow/ContactShadow") != null, "enemy has contact and cast shadows")
	enemy.velocity = Vector2(96.0, 0.0)
	enemy_visual._process_enemy(1.0 / 60.0)
	check(enemy.global_position == enemy_root_before and enemy_collision.global_transform == enemy_collision_before, "enemy grounding does not move gameplay root or collision")
	check(enemy.contact_radius == contact_before and enemy.hit_radius == hit_before, "enemy contact and hit radii remain unchanged")
	check(enemy_visual._enemy_anim.animation == &"move" and enemy_visual._enemy_anim.position == Vector2.ZERO and enemy_visual._enemy_anim.rotation == 0.0, "production motion comes from rendered move frames without procedural wobble")

	# The snow system allocates exactly eight reusable sprites and drops request 9.
	var pool_host := Node2D.new()
	root.add_child(pool_host)
	var pool := GroundingEffectPool.new()
	pool_host.add_child(pool)
	await process_frame
	var accepted: int = 0
	for index: int in range(9):
		if pool.request(GroundingEffectPool.Effect.KICK, Vector2(index * 4.0, 0.0), 0.0, Vector2.ONE * 0.5):
			accepted += 1
	check(pool.capacity() == 8 and pool.get_child_count() == 8, "snow pool is fixed at eight preallocated sprites")
	check(accepted == 8 and pool.active_count() == 8, "full snow pool drops the ninth request without allocating")
	pool_host.free()

	arena.free()
	print("ACTOR GROUNDING V1 TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
