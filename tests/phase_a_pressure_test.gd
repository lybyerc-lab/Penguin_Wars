extends SceneTree
## Focused population and production-geometry spawn-pressure regression.

var failures: int = 0
const DRIFTFIELD: EncounterDefinition = preload("res://resources/encounters/driftfield_phase_a.tres")
const DRIFTFIELD_ROOM: RoomDefinition = preload("res://resources/rooms/driftfield_phase_a.tres")
const REVIEW_SCENE: PackedScene = preload("res://scenes/prototypes/phase_a_expedition_review.tscn")
const ARENA_SCENE: PackedScene = preload("res://scenes/arena/test_arena.tscn")

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _make_arena(player_count: int) -> Node2D:
	var arena := ARENA_SCENE.instantiate() as Node2D
	arena.set("player_count", player_count)
	root.add_child(arena)
	await process_frame
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	return arena

func _clear_enemies(actor_root: Node2D, director: EncounterDirector) -> void:
	for node: Node in actor_root.get_children():
		if node is ArenaEnemy:
			node.free()
	director.alive_count = 0

func _role_counts(actor_root: Node2D) -> Dictionary:
	var counts := {"rolly": 0, "skua": 0, "tuskbull": 0}
	for node: Node in actor_root.get_children():
		if node is not ArenaEnemy:
			continue
		var enemy := node as ArenaEnemy
		if enemy.behavior is RangedBehavior:
			counts["skua"] += 1
		elif enemy.behavior is ChargeBehavior:
			counts["tuskbull"] += 1
		else:
			counts["rolly"] += 1
	return counts

func _spawn_positions(director: EncounterDirector, count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for index: int in range(count):
		director._spawn_enemy()
		var children: Array[Node] = director.actor_root.get_children()
		for child_index: int in range(children.size() - 1, -1, -1):
			if children[child_index] is ArenaEnemy:
				(children[child_index] as ArenaEnemy).set_physics_process(false)
				positions.append((children[child_index] as ArenaEnemy).global_position)
				break
	return positions

func _normalized_angle(director: EncounterDirector, point: Vector2) -> float:
	var centre: Vector2 = director._party_center() if director.definition.spawn_mode == EncounterDefinition.SpawnMode.PARTY_OFFSCREEN else director.spawn_center
	var extents: Vector2 = director.definition.offscreen_half_extents if director.definition.spawn_mode == EncounterDefinition.SpawnMode.PARTY_OFFSCREEN else director.spawn_ring
	var offset: Vector2 = point - centre
	return fposmod(atan2(offset.y / extents.y, offset.x / extents.x), TAU)

func _sector_for(director: EncounterDirector, point: Vector2) -> int:
	return floori(_normalized_angle(director, point) / (TAU / float(EncounterDirector.SPAWN_SECTOR_COUNT)))

func _angular_distance(a: float, b: float) -> float:
	var distance: float = absf(a - b)
	return minf(distance, TAU - distance)

func _collision_clear(actor_root: Node2D, candidate: Vector2, destination: Vector2) -> bool:
	var space: PhysicsDirectSpaceState2D = actor_root.get_world_2d().direct_space_state
	var point := PhysicsPointQueryParameters2D.new()
	point.position = candidate
	point.collision_mask = EncounterDirector.WORLD_COLLISION_MASK
	point.collide_with_areas = false
	point.collide_with_bodies = true
	if not space.intersect_point(point, 1).is_empty():
		return false
	var ray := PhysicsRayQueryParameters2D.create(candidate, destination, EncounterDirector.WORLD_COLLISION_MASK)
	ray.collide_with_areas = false
	ray.collide_with_bodies = true
	return space.intersect_ray(ray).is_empty()

func _run() -> void:
	var expected := {
		1: PackedInt32Array([9, 12, 15, 18]),
		2: PackedInt32Array([12, 15, 18, 21]),
		3: PackedInt32Array([15, 18, 21, 24]),
		4: PackedInt32Array([18, 21, 24, 27]),
	}
	for player_count: int in range(1, 5):
		var arena: Node2D = await _make_arena(player_count)
		var director := arena.get_node("Encounter") as EncounterDirector
		director.reset()
		director.definition = DRIFTFIELD
		director._rng.seed = DRIFTFIELD.run_seed
		var observed := PackedInt32Array()
		for wave_number: int in range(1, 5):
			director.wave = wave_number - 1
			director._begin_wave()
			observed.append(director._left)
		check(observed == expected[player_count],
			"%d-player director population follows the provisional additive pressure rule" % player_count)
		arena.free()

	# Drive the actual clear-all lifecycle through all four denser solo waves.
	var solo: Node2D = await _make_arena(1)
	var solo_director := solo.get_node("Encounter") as EncounterDirector
	solo_director.reset()
	solo_director.definition = DRIFTFIELD
	solo_director.auto_advance = true
	solo_director.start()
	for step: int in range(300):
		solo_director._physics_process(10.0)
		for node: Node in solo_director.actor_root.get_children():
			if node is ArenaEnemy:
				(node as ArenaEnemy).set_physics_process(false)
				if (node as ArenaEnemy).health.is_alive():
					(node as ArenaEnemy).health.take_damage(DamageEvent.new(1000.0, 1))
		await process_frame
		if solo_director.state == EncounterDirector.State.COMPLETE:
			break
	check(solo_director.state == EncounterDirector.State.COMPLETE and solo_director.wave == 4,
		"denser solo Driftfield encounter still resolves all four waves")
	solo.free()

	# Four-player maximum pressure still keeps special roles readable; added
	# population is carried by Rollies rather than multiplying every role.
	var coop: Node2D = await _make_arena(4)
	var coop_director := coop.get_node("Encounter") as EncounterDirector
	coop_director.reset()
	coop_director.definition = DRIFTFIELD
	coop_director.wave = 4
	coop_director._spawn_index = 0
	coop_director._rng.seed = DRIFTFIELD.run_seed
	coop_director._configure_pressure_sectors()
	for index: int in range(DRIFTFIELD.population_for_wave(4, 4)):
		coop_director._spawn_enemy()
	var roles: Dictionary = _role_counts(coop_director.actor_root)
	check(roles == {"rolly": 23, "skua": 2, "tuskbull": 2},
		"four-player wave 4 respects the authored two-charger/two-ranged caps")
	coop.free()

	# Exercise the split-sector selector against the real production collision.
	var run := REVIEW_SCENE.instantiate() as Node2D
	root.add_child(run)
	await process_frame
	run._enter_room(DRIFTFIELD_ROOM)
	await physics_frame
	var production_director: EncounterDirector = run.encounter
	production_director.set_physics_process(false)
	_clear_enemies(production_director.actor_root, production_director)
	production_director.wave = 4
	production_director._spawn_index = 0
	production_director._rng.seed = DRIFTFIELD.run_seed
	production_director._configure_pressure_sectors()
	var first_positions: Array[Vector2] = _spawn_positions(production_director, 8)
	var first_sectors: PackedInt32Array = production_director._pressure_sectors.duplicate()

	check(first_positions.size() == 8 and first_sectors.size() == 2,
		"production selector produces both seeded pressure lanes")
	if first_positions.size() == 8:
		var party_center: Vector2 = production_director._party_center()
		for position: Vector2 in first_positions:
			var relative := position - party_center
			check(absf(relative.x) >= 807.0 or absf(relative.y) >= 372.0,
				"production spawns stay outside the 1560x720 gameplay view")
			check(absf(relative.x) <= 881.0 and absf(relative.y) <= 441.0,
				"production spawns stay within the authored offscreen perimeter")
			check(production_director.actor_bounds.grow(-EncounterDirector.SPAWN_EDGE_MARGIN).has_point(position),
				"spawn stays inside inset Driftfield encounter bounds")
			check(_collision_clear(production_director.actor_root, position, party_center),
				"spawn stays outside authored collision with a clear route toward the party")

	_clear_enemies(production_director.actor_root, production_director)
	production_director._spawn_index = 0
	production_director._rng.seed = DRIFTFIELD.run_seed
	production_director._configure_pressure_sectors()
	var repeated_positions: Array[Vector2] = _spawn_positions(production_director, 8)
	check(production_director._pressure_sectors == first_sectors and repeated_positions == first_positions,
		"same run seed reproduces the same sectors and production spawn positions")

	# Heading sectors are role-aware without creating a second spawn system.
	production_director._smoothed_heading = Vector2.RIGHT
	production_director._rng.seed = DRIFTFIELD.run_seed
	var base_a: int = production_director._primary_sector_for(0, &"base")
	var base_b: int = production_director._primary_sector_for(1, &"base")
	var ranged: int = production_director._primary_sector_for(2, &"ranged")
	var charger: int = production_director._primary_sector_for(3, &"charger")
	check(base_a == 0 and base_b == 4, "base pressure alternates heading and opposite sectors")
	check(ranged == 0, "ranged pressure follows the party heading")
	check(charger in [2, 6], "charger pressure arrives from a heading flank")

	run.free()
	print("PHASE A PRESSURE TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
