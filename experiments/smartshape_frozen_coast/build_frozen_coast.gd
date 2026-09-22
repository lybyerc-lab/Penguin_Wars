extends SceneTree
## EXPERIMENT — rebuilds frozen_coast.tscn from the layout below.
##
##   godot --headless --path . --script res://experiments/smartshape_frozen_coast/build_frozen_coast.gd
##
## In real use an author places these points by hand in the SmartShape editor
## and no script like this exists. It is here so the spike is reproducible and
## reviewable; the editor session (editor_session.gd) then opens, edits and
## re-saves the result through the real editor to judge the authoring side.
##
## Coordinates are room-local, matching frozen_coast_room.tres. The terrain is
## drawn to sit over those bounds; it does not define them.

const DIR := "res://experiments/smartshape_frozen_coast/"
const TERRAIN := DIR + "terrain/"

## [position, smooth] — smooth points get Catmull-Rom style bezier handles, the
## way an author drags them; sharp points keep none.
const SHELF := [
	[Vector2(690, -95), false], [Vector2(600, -95), true], [Vector2(440, -112), true],
	[Vector2(262, -168), true], [Vector2(128, -262), true], [Vector2(-110, -300), true],
	[Vector2(-330, -284), true], [Vector2(-515, -212), true], [Vector2(-598, -60), true],
	[Vector2(-584, 140), true], [Vector2(-492, 270), true], [Vector2(-396, 214), true],
	[Vector2(-300, 300), true], [Vector2(-110, 312), true], [Vector2(54, 286), true],
	[Vector2(166, 210), true], [Vector2(310, 124), true], [Vector2(448, 104), true],
	[Vector2(600, 95), true], [Vector2(690, 95), false],
]
const TIDE_POOL := [
	[Vector2(-330, 120), true], [Vector2(-250, 88), true], [Vector2(-178, 118), true],
	[Vector2(-196, 168), true], [Vector2(-282, 176), true],
]
const SNOWBANK := [
	[Vector2(-450, -176), false], [Vector2(-330, -214), true], [Vector2(-190, -204), true],
	[Vector2(-70, -232), false],
]
const FLOES := [
	[[Vector2(380, -250), true], [Vector2(470, -272), true], [Vector2(540, -226), true], [Vector2(452, -196), true]],
	[[Vector2(470, 190), true], [Vector2(560, 176), true], [Vector2(590, 236), true], [Vector2(500, 258), true]],
	[[Vector2(250, 262), true], [Vector2(320, 244), true], [Vector2(338, 290), true], [Vector2(270, 300), true]],
]

func _initialize() -> void:
	call_deferred("_build")

func _typed_textures(paths: Array) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	for path: String in paths:
		result.append(load(TERRAIN + path) as Texture2D)
	return result

func _edge(file: String, textures: Array, tapers: Array) -> SS2D_Material_Edge:
	var edge := SS2D_Material_Edge.new()
	edge.textures = _typed_textures(textures)
	edge.textures_taper_left = _typed_textures([tapers[0]])
	edge.textures_taper_right = _typed_textures([tapers[1]])
	edge.use_corner_texture = false
	edge.use_taper_texture = true
	ResourceSaver.save(edge, TERRAIN + file, ResourceSaver.FLAG_CHANGE_PATH)
	return edge

func _meta(edge: SS2D_Material_Edge, begin: float, distance: float, offset: float) -> SS2D_Material_Edge_Metadata:
	var meta := SS2D_Material_Edge_Metadata.new()
	meta.edge_material = edge
	meta.normal_range = SS2D_NormalRange.new(begin, distance)
	meta.weld = true
	meta.offset = offset
	return meta

func _shape_material(file: String, fill: String, metas: Array) -> SS2D_Material_Shape:
	var material := SS2D_Material_Shape.new()
	if fill != "":
		material.fill_textures = _typed_textures([fill])
	var typed: Array[SS2D_Material_Edge_Metadata] = []
	for meta: SS2D_Material_Edge_Metadata in metas:
		typed.append(meta)
	material.set_edge_meta_materials(typed)
	ResourceSaver.save(material, TERRAIN + file, ResourceSaver.FLAG_CHANGE_PATH)
	return material

func _shape(shape_name: String, material: SS2D_Material_Shape, layout: Array, closed: bool, width: float = 1.0) -> SS2D_Shape:
	var shape := SS2D_Shape.new()
	shape.name = shape_name
	shape.shape_material = material
	var points: SS2D_Point_Array = shape.get_point_array()
	points.begin_update()
	var count: int = layout.size()
	for index: int in range(count):
		var here: Vector2 = layout[index][0]
		var key: int = points.add_point(here)
		points.get_point(key).width = width
		if not layout[index][1]:
			continue
		var before: Vector2 = layout[(index - 1 + count) % count][0] if closed or index > 0 else here
		var after: Vector2 = layout[(index + 1) % count][0] if closed or index < count - 1 else here
		var tangent: Vector2 = (after - before) * 0.18
		points.set_point_in(key, -tangent)
		points.set_point_out(key, tangent)
	if closed:
		points.close_shape()
	points.end_update()
	# SmartShape picks edge materials from outward normals, which only holds for
	# clockwise points. Its editor actions re-wind shapes silently; the data API
	# does not, so a scripted author has to do what the editor would.
	if closed and not points.are_points_clockwise():
		points.invert_point_order()
	return shape

func _build() -> void:
	# A camera-facing cliff on edges whose normal points down the screen, and a
	# soft snow lip everywhere else. Angles follow SmartShape's convention:
	# 90 is screen-up, 270 is screen-down.
	var cliff := _edge("edge_cliff.tres", ["cliff_edge.png"], ["cliff_taper_left.png", "cliff_taper_right.png"])
	var lip := _edge("edge_lip.tres", ["snow_lip_edge.png"], ["lip_taper_left.png", "lip_taper_right.png"])
	# The cliff is kept to near-horizontal edges. SmartShape extrudes a strip
	# along each edge's normal, which suits a side-on game; a top-down cliff face
	# should always drop straight down the screen, so on steep diagonals the
	# strip reads as a slanted slab. Those edges take the lip instead.
	var shelf_material := _shape_material("shelf_material.tres", "snow_fill.png", [
		_meta(cliff, 240.0, 60.0, 0.5),
		_meta(lip, 300.0, 300.0, 0.0),
	])
	var ice_material := _shape_material("ice_material.tres", "ice_fill.png", [
		_meta(cliff, 240.0, 60.0, 0.5),
		_meta(lip, 300.0, 300.0, 0.0),
	])
	var bank_material := _shape_material("snowbank_material.tres", "", [
		_meta(cliff, 0.0, 0.0, 0.0),
	])

	var terrain := Node2D.new()
	terrain.name = "Terrain"
	var collision := StaticBody2D.new()
	collision.name = "ShelfCollision"
	# Inert by design. See frozen_coast.gd: a live layer would make SmartShape a
	# geography authority. The verifier turns it on only to measure it.
	collision.collision_layer = 0
	collision.collision_mask = 0
	var polygon := CollisionPolygon2D.new()
	polygon.name = "Polygon"
	polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	collision.add_child(polygon)

	var shelf := _shape("Shelf", shelf_material, SHELF, true)
	shelf.collision_generation_method = SS2D_Shape.CollisionGenerationMethod.Default
	shelf.collision_offset = -6.0
	terrain.add_child(shelf)
	terrain.add_child(_shape("TidePool", ice_material, TIDE_POOL, true, 0.35))
	var bank := _shape("Snowbank", bank_material, SNOWBANK, false, 0.5)
	# An open shape takes its facing from point direction, not winding; without
	# this the face points up the screen and the bank reads as a trench.
	bank.flip_edges = true
	terrain.add_child(bank)
	for index: int in range(FLOES.size()):
		terrain.add_child(_shape("Floe%d" % (index + 1), ice_material, FLOES[index], true, 0.4))
	terrain.add_child(collision)
	shelf.collision_polygon_node_path = NodePath("../ShelfCollision/Polygon")

	# Outside the editor, Editor-mode collision never bakes. Bake once here the
	# way the editor would, then store the shape in Editor mode so a shipped
	# scene never regenerates collision at runtime.
	shelf.collision_update_mode = SS2D_Shape.CollisionUpdateMode.EditorAndRuntime
	root.add_child(terrain)
	await process_frame
	for node: Node in terrain.get_children():
		if node is SS2D_Shape:
			node.force_update()
	shelf.collision_update_mode = SS2D_Shape.CollisionUpdateMode.Editor
	await process_frame
	root.remove_child(terrain)

	var scene_root := Node2D.new()
	scene_root.name = "FrozenCoast"
	scene_root.set_script(load(DIR + "frozen_coast.gd"))
	var ocean := Polygon2D.new()
	ocean.name = "Ocean"
	ocean.texture = load(TERRAIN + "ocean_fill.png")
	ocean.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ocean.polygon = PackedVector2Array([Vector2(-1100, -760), Vector2(1100, -760), Vector2(1100, 760), Vector2(-1100, 760)])
	ocean.uv = ocean.polygon
	# SmartShape draws fills at z -10 by default, so a backdrop at z 0 hides them.
	ocean.z_index = -100
	scene_root.add_child(ocean)
	scene_root.add_child(terrain)
	for pair: Array in [["Party", "res://scripts/party/party_roster.gd", "Node"], ["Wallet", "res://scripts/progression/run_wallet.gd", "Node"], ["Loot", "res://scripts/loot/arena_loot.gd", "Node"], ["Builder", "res://scripts/defenses/castle_builder.gd", "Node"], ["Progression", "res://scripts/progression/run_progression.gd", "Node"], ["Encounter", "res://scripts/encounters/encounter_director.gd", "Node"]]:
		var system: Node = Node.new()
		system.name = pair[0]
		system.set_script(load(pair[1]))
		scene_root.add_child(system)
	for plain: String in ["Places", "Actors"]:
		var holder := Node2D.new()
		holder.name = plain
		scene_root.add_child(holder)
	var camera := Camera2D.new()
	camera.name = "Camera"
	camera.set_script(load("res://scripts/camera/party_camera.gd"))
	scene_root.add_child(camera)
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(load("res://scripts/ui/arena_hud.gd"))
	scene_root.add_child(hud)
	_own(scene_root, scene_root)

	var packed := PackedScene.new()
	var result: Error = packed.pack(scene_root)
	if result == OK:
		result = ResourceSaver.save(packed, DIR + "frozen_coast.tscn")
	# The packed copy is on disk; free the working tree so the build exits clean
	# and any leak reported afterwards is the plugin's, not this script's.
	scene_root.free()
	print("FROZEN COAST BUILD: ", "PASS" if result == OK else "FAIL %d" % result)
	quit(0 if result == OK else 1)

func _own(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		_own(child, owner_node)
