extends SceneTree
## EXPERIMENT — headless checks for the SmartShape2D spike.
##
##   godot --headless --path . --script res://experiments/smartshape_frozen_coast/verify_frozen_coast.gd
##
## Two jobs. First, prove RoomDefinition is still the only geography authority
## with SmartShape in the room. Second, MEASURE SmartShape's editor-baked
## collision by switching it on inside this test only — the shipped scene keeps
## it inert — and report which systems would and would not respect it.
## Measurements print as "MEASURE:" lines; pass/fail checks as "FAIL:".

const SCENE := "res://experiments/smartshape_frozen_coast/frozen_coast.tscn"
const ROOM := "res://experiments/smartshape_frozen_coast/frozen_coast_room.tres"
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func measure(label: String, value: Variant) -> void:
	print("MEASURE: %s = %s" % [label, str(value)])

func _snapshot(resource: Resource) -> Dictionary:
	var values := {}
	for property: Dictionary in resource.get_property_list():
		if property.usage & PROPERTY_USAGE_STORAGE:
			values[property.name] = str(resource.get(property.name))
	return values

func _spawn(players: int, collision_live: bool) -> Node2D:
	var run := (load(SCENE) as PackedScene).instantiate() as Node2D
	run.player_count = players
	if collision_live:
		var body := run.get_node("Terrain/ShelfCollision") as StaticBody2D
		body.collision_layer = 1
	root.add_child(run)
	await process_frame
	await physics_frame
	return run

func _coast(run: Node2D) -> PackedVector2Array:
	var polygon := run.get_node("Terrain/ShelfCollision/Polygon") as CollisionPolygon2D
	return polygon.global_transform * polygon.polygon

func _steer(players: Array[PenguinPlayer], direction: Vector2, frames: int) -> void:
	for player: PenguinPlayer in players:
		player.input_source.touch_movement = direction
	for frame: int in range(frames):
		await physics_frame
	for player: PenguinPlayer in players:
		player.input_source.touch_movement = Vector2.ZERO

func _shapes(run: Node2D) -> Array[SS2D_Shape]:
	var found: Array[SS2D_Shape] = []
	for node: Node in run.get_node("Terrain").get_children():
		if node is SS2D_Shape:
			found.append(node)
	return found

func _run() -> void:
	var room: RoomDefinition = load(ROOM)
	var room_before: Dictionary = _snapshot(room)
	var exits_before: Array[Dictionary] = []
	for spec: RoomExit in room.exits:
		exits_before.append(_snapshot(spec))

	# ---------- 1. RoomDefinition stays the geography authority ----------
	var run: Node2D = await _spawn(4, false)
	for frame: int in range(20):
		await process_frame
	var players: Array[PenguinPlayer] = run.party.members()
	check(players.size() == 4, "the prototype spawns a full party")
	for player: PenguinPlayer in players:
		check(player.arena_bounds == room.bounds, "players take their clamp from RoomDefinition.bounds")
	check(run.encounter.actor_bounds == room.bounds, "the director takes its bounds from RoomDefinition")
	check(run.encounter.spawn_ring == room.spawn_ring, "the spawn ring comes from RoomDefinition")
	check(run.get_node("Builder").build_bounds == room.build_bounds(), "castle placement comes from RoomDefinition")
	check(run.get_node("Loot").supply_points == room.supply_points, "supply placement comes from RoomDefinition")
	check(run.get_node("Camera").framed_size == room.bounds.size + RoomSpace.VIEW_MARGIN, "camera framing comes from RoomDefinition")
	var gates: Array[PartyGate] = run.gates()
	check(gates.size() == room.exits.size(), "one doorway per RoomExit")
	check(gates[0].position == room.exits[0].place_on(room.bounds), "the doorway is placed by RoomExit.place_on, as in production")
	check(gates[0].exit == room.exits[0], "the doorway carries the RoomDefinition's own exit")

	var body := run.get_node("Terrain/ShelfCollision") as StaticBody2D
	check(body.collision_layer == 0 and body.collision_mask == 0, "SmartShape collision ships inert")

	# Force every shape through a full rebuild and prove the room data is untouched.
	for shape: SS2D_Shape in _shapes(run):
		shape.force_update()
		shape.set_as_dirty()
	for frame: int in range(5):
		await process_frame
	# Positive control for the regeneration check in section 2: a forced rebuild
	# must be visible through _edges, or "nothing rebuilt" would prove nothing.
	var forced_visible: int = 0
	for shape: SS2D_Shape in _shapes(run):
		if not shape._edges.is_empty():
			forced_visible += 1
	check(forced_visible == _shapes(run).size(), "a forced rebuild is detectable (control for the no-regeneration check)")
	check(_snapshot(room) == room_before, "SmartShape rebuilds never write to RoomDefinition")
	for index: int in range(room.exits.size()):
		check(_snapshot(room.exits[index]) == exits_before[index], "SmartShape rebuilds never write to RoomExit")

	# The terrain holds no gameplay references, and the room data knows nothing of SmartShape.
	var scene_text := FileAccess.get_file_as_string(SCENE)
	var room_text := FileAccess.get_file_as_string(ROOM)
	check(not room_text.contains("rmsmartshape"), "RoomDefinition data has no SmartShape dependency")
	var terrain_start: int = scene_text.find("[node name=\"Terrain\"")
	check(terrain_start > 0, "the scene has a Terrain section")
	var terrain_text: String = scene_text.substr(terrain_start)
	for forbidden: String in ["room_definition", "room_exit", "encounter", "entry_point", "bounds ="]:
		check(not terrain_text.contains(forbidden), "no gameplay field '%s' is stored under Terrain" % forbidden)

	# ---------- 2. Runtime regeneration ----------
	var fresh: Node2D = await _spawn(1, false)
	for frame: int in range(120):
		await process_frame
	var meshes: int = 0
	var vertices: int = 0
	var canvas_items: int = 0
	var rebuilt: int = 0
	for shape: SS2D_Shape in _shapes(fresh):
		meshes += shape._mesh_cache.meshes.size()
		canvas_items += shape._renderer._render_nodes.size()
		for cached: SS2D_Mesh in shape._mesh_cache.meshes:
			for surface: int in range(cached.mesh.get_surface_count()):
				vertices += cached.mesh.surface_get_array_len(surface)
		# _edges is only filled by _build_meshes(); empty after 120 frames means
		# the serialized mesh cache was rendered as-is and nothing was rebuilt.
		if not shape._edges.is_empty():
			rebuilt += 1
	measure("SS2D shapes", _shapes(fresh).size())
	measure("cached meshes (one RenderingServer canvas item each)", meshes)
	measure("canvas items created by SS2D renderers", canvas_items)
	measure("cached vertices", vertices)
	measure("shapes that rebuilt meshes at runtime", rebuilt)
	check(rebuilt == 0, "shipped shapes render their saved mesh cache without rebuilding")
	check(meshes > 0 and canvas_items == meshes, "every cached mesh gets exactly one canvas item")
	var saved_polygon: PackedVector2Array = (load(SCENE) as PackedScene).instantiate().get_node("Terrain/ShelfCollision/Polygon").polygon
	var live_polygon: PackedVector2Array = (fresh.get_node("Terrain/ShelfCollision/Polygon") as CollisionPolygon2D).polygon
	check(live_polygon == saved_polygon, "Editor-mode collision is not regenerated at runtime")
	measure("baked collision vertices", live_polygon.size())
	var terrain_nodes: int = 0
	var stack: Array[Node] = [fresh.get_node("Terrain")]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		terrain_nodes += 1
		for child: Node in node.get_children():
			stack.append(child)
	measure("scene-tree nodes under Terrain", terrain_nodes)
	fresh.queue_free()

	# ---------- 3. Collision quality ----------
	var coast: PackedVector2Array = _coast(run)
	var zero_edges: int = 0
	var sharpest: float = 180.0
	for index: int in range(coast.size()):
		var a: Vector2 = coast[index]
		var b: Vector2 = coast[(index + 1) % coast.size()]
		var c: Vector2 = coast[(index + 2) % coast.size()]
		if a.distance_to(b) < 0.5:
			zero_edges += 1
		var turn: float = rad_to_deg((a - b).angle_to(c - b))
		sharpest = minf(sharpest, absf(turn))
	var crossings: int = 0
	for i: int in range(coast.size()):
		for j: int in range(i + 2, coast.size()):
			if i == 0 and j == coast.size() - 1:
				continue
			if Geometry2D.segment_intersects_segment(coast[i], coast[(i + 1) % coast.size()], coast[j], coast[(j + 1) % coast.size()]) != null:
				crossings += 1
	var outline: PackedVector2Array = _shapes(run)[0].global_transform * _shapes(run)[0].get_point_array().get_tessellated_points()
	var drift: float = 0.0
	for point: Vector2 in coast:
		var nearest: float = INF
		for index: int in range(outline.size() - 1):
			nearest = minf(nearest, point.distance_to(Geometry2D.get_closest_point_to_segment(point, outline[index], outline[index + 1])))
		drift = maxf(drift, nearest)
	measure("collision near-zero-length edges", zero_edges)
	measure("collision self-intersections", crossings)
	measure("sharpest collision vertex angle (deg)", snappedf(sharpest, 0.1))
	measure("max distance collision vs visual outline (px, offset is 6)", snappedf(drift, 0.01))
	check(zero_edges == 0, "no zero-length slivers in the baked collision")
	check(crossings == 0, "the baked collision does not cross itself")
	check(drift < 12.0, "the baked collision follows the drawn coast")
	run.queue_free()

	# ---------- 4. Traversal with collision switched on ----------
	var shore: Node2D = await _spawn(1, false)
	var coastline: PackedVector2Array = _coast(shore)
	shore.queue_free()
	var inert_sea: Vector2 = await _walk_north(false)
	var live_sea: Vector2 = await _walk_north(true)
	measure("walk north from passage, collision inert: final y", snappedf(inert_sea.y, 0.01))
	measure("walk north from passage, collision live: final y", snappedf(live_sea.y, 0.01))
	check(inert_sea.y <= room.bounds.position.y + 1.0, "inert: only the RoomDefinition clamp stops the penguin, out over the sea")
	check(not Geometry2D.is_point_in_polygon(inert_sea, coastline), "inert: the penguin ends up standing on drawn sea")
	check(Geometry2D.is_point_in_polygon(live_sea, coastline), "live: the coast keeps the penguin on land")

	var first: Vector2 = await _walk_to_door()
	var second: Vector2 = await _walk_to_door()
	measure("clearing to doorway, run 1 final position", first)
	measure("clearing to doorway, run 2 final position", second)
	check(first == second, "collision traversal is deterministic run to run")

	var door: Node2D = await _spawn(4, true)
	var party: Array[PenguinPlayer] = door.party.members()
	var gate: PartyGate = door.gates()[0]
	var starts: Array[Vector2] = [Vector2(380, -50), Vector2(380, 50), Vector2(320, -30), Vector2(320, 40)]
	for index: int in range(party.size()):
		party[index].global_position = starts[index]
	await physics_frame
	await _steer(party, Vector2.RIGHT, 150)
	measure("penguins inside the doorway threshold with collision live", gate.standing())
	check(gate.standing() == 4, "four penguins can still fill the doorway with collision live")
	door.queue_free()

	var corner: Node2D = await _spawn(1, true)
	var hugger: PenguinPlayer = corner.party.members()[0]
	hugger.global_position = Vector2(120, -120)
	await physics_frame
	await _steer([hugger], Vector2(1, -1).normalized(), 90)
	measure("diagonal push along the north shoulder: final position", hugger.global_position)
	measure("diagonal push: distance travelled while sliding", snappedf(hugger.global_position.distance_to(Vector2(120, -120)), 0.1))
	check(Geometry2D.is_point_in_polygon(hugger.global_position, coastline), "pushing into the curved shoulder never clips through it")
	check(hugger.global_position.distance_to(Vector2(120, -120)) > 40.0, "a penguin pushed into the shoulder slides along it rather than sticking")
	corner.queue_free()

	# ---------- 5. What would ignore SmartShape collision ----------
	var sample: Node2D = await _spawn(1, false)
	var land: PackedVector2Array = _coast(sample)
	var ring_misses: int = 0
	for step: int in range(360):
		var angle: float = deg_to_rad(step)
		var at: Vector2 = room.bounds.get_center() + Vector2(cos(angle) * room.spawn_ring.x, sin(angle) * room.spawn_ring.y)
		if not Geometry2D.is_point_in_polygon(at, land):
			ring_misses += 1
	var build_misses: int = 0
	var build_total: int = 0
	var build: Rect2 = room.build_bounds()
	for x: int in range(int(build.position.x), int(build.end.x), 20):
		for y: int in range(int(build.position.y), int(build.end.y), 20):
			build_total += 1
			if not Geometry2D.is_point_in_polygon(Vector2(x, y), land):
				build_misses += 1
	var rect_area: float = room.bounds.get_area()
	var sea_area: float = 0.0
	var rect_polygon := PackedVector2Array([room.bounds.position, Vector2(room.bounds.end.x, room.bounds.position.y), room.bounds.end, Vector2(room.bounds.position.x, room.bounds.end.y)])
	for part: PackedVector2Array in Geometry2D.clip_polygons(rect_polygon, land):
		sea_area += absf(_area(part))
	measure("spawn-ring points drawn as sea (of 360)", ring_misses)
	measure("castle-placement samples drawn as sea", "%d of %d (%.0f%%)" % [build_misses, build_total, 100.0 * build_misses / build_total])
	measure("share of RoomDefinition.bounds drawn as sea", "%.0f%%" % (100.0 * sea_area / rect_area))
	for point: Vector2 in room.supply_points:
		check(Geometry2D.is_point_in_polygon(point, land), "supply point %s sits on drawn land" % point)
	check(Geometry2D.is_point_in_polygon(room.entry_point, land), "the entry point sits on drawn land")
	measure("player collision_mask includes World", bool(sample.party.members()[0].collision_mask & 1))
	var seal := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as ArenaEnemy
	measure("enemy collision_mask includes World", bool(seal.collision_mask & 1))
	measure("enemy snowball base type (no physics body)", (load("res://scripts/enemies/enemy_snowball.gd") as GDScript).get_instance_base_type())
	measure("castle snowball base type (no physics body)", (load("res://scripts/defenses/castle_snowball.gd") as GDScript).get_instance_base_type())
	seal.free()
	sample.queue_free()

	await process_frame
	print("FROZEN COAST VERIFY: ", "PASS" if failures == 0 else "FAIL", " (%d failures)" % failures)
	quit(0 if failures == 0 else 1)

func _area(polygon: PackedVector2Array) -> float:
	var total: float = 0.0
	for index: int in range(polygon.size()):
		var a: Vector2 = polygon[index]
		var b: Vector2 = polygon[(index + 1) % polygon.size()]
		total += a.x * b.y - b.x * a.y
	return total * 0.5

func _walk_north(collision_live: bool) -> Vector2:
	var run: Node2D = await _spawn(1, collision_live)
	var penguin: PenguinPlayer = run.party.members()[0]
	penguin.global_position = Vector2(400, 0)
	await physics_frame
	await _steer([penguin], Vector2.UP, 120)
	var final_position: Vector2 = penguin.global_position
	run.queue_free()
	await process_frame
	return final_position

func _walk_to_door() -> Vector2:
	var run: Node2D = await _spawn(1, true)
	var penguin: PenguinPlayer = run.party.members()[0]
	penguin.global_position = Vector2(-300, 60)
	await physics_frame
	await _steer([penguin], Vector2(1, -0.2).normalized(), 150)
	await _steer([penguin], Vector2.RIGHT, 150)
	var final_position: Vector2 = penguin.global_position
	run.queue_free()
	await process_frame
	return final_position
