class_name FrozenCoastPhaseAVisual
extends Node2D
## Presentation/collision adapter for the approved Frozen Coast Phase A plate.
## Gameplay authority stays in Expedition + RoomDefinition + EncounterDefinition.

const ASSET_ROOT := "res://assets/environments/frozen_coast_phase_a_v0_1/"
const MANIFEST_PATH := ASSET_ROOT + "frozen_coast_phase_a_manifest_v0_1_candidate.json"
const GUIDES_PATH := ASSET_ROOT + "frozen_coast_phase_a_guides_v0_1.json"
const RIM_ALPHA: float = 0.45
const NO_STUN_GROUP := &"tuskbull_no_stun"
const ENEMY_PHYSICS_LAYER_MASK: int = 4
const ACTOR_SUN_META := &"actor_sun"

var actor_layer: Node2D
var _actor_occluders: Array[Node2D] = []
var _soft_zones: Array[Area2D] = []
var _soft_drift_behaviors: Dictionary = {}
var _hard_bodies: Array[StaticBody2D] = []
var _manifest: Dictionary = {}
var _guides: Dictionary = {}

static func build(into: Node2D, actors: Node2D) -> FrozenCoastPhaseAVisual:
	var visual := FrozenCoastPhaseAVisual.new()
	visual.name = "FrozenCoastPhaseAVisual"
	visual.actor_layer = actors
	into.add_child(visual)
	return visual

func _ready() -> void:
	z_index = -8
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	get_tree().set_meta(ACTOR_SUN_META, {
		"region": &"frozen_coast",
		"angle_deg": -51.6,
		"len_per_m": 139.2,
	})
	_manifest = _load_json(MANIFEST_PATH, "Frozen Coast Phase A manifest")
	_guides = _load_json(GUIDES_PATH, "Frozen Coast Phase A guides")
	if _manifest.is_empty() or _guides.is_empty():
		return
	_build_background()
	_build_occluders()
	_build_collision()
	_build_soft_zones()

func _physics_process(_delta: float) -> void:
	if actor_layer == null or _soft_zones.is_empty():
		return
	var current: Dictionary = {}
	for child: Node in actor_layer.get_children():
		if child is not Node2D:
			continue
		var charge := _soft_drift_behavior(child as Node2D)
		if charge == null:
			continue
		var in_soft_drift := false
		for area: Area2D in _soft_zones:
			var polygon := area.get_child(0) as CollisionPolygon2D
			if Geometry2D.is_point_in_polygon(area.to_local((child as Node2D).global_position), polygon.polygon):
				in_soft_drift = true
				break
		charge.set_soft_charge_active(in_soft_drift)
		current[charge] = true
	for prior: Variant in _soft_drift_behaviors:
		if is_instance_valid(prior) and not current.has(prior):
			(prior as ChargeBehavior).set_soft_charge_active(false)
	_soft_drift_behaviors = current

func foreground_layer_count() -> int:
	return _actor_occluders.size()

func hard_body_count() -> int:
	return _hard_bodies.size()

func soft_zone_count() -> int:
	return _soft_zones.size()

func layer_root(layer_name: StringName) -> Node2D:
	for root: Node2D in _actor_occluders:
		if root.get_meta(&"frozen_coast_visual_layer", &"") == layer_name:
			return root
	return null

func _load_json(path: String, label: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("%s is missing: %s" % [label, path])
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is not Dictionary:
		push_error("%s is invalid JSON" % label)
		return {}
	return parsed as Dictionary

func _build_background() -> void:
	# The approved 3584x2816 plate is stored as four lossless 1792x1408 tiles.
	# This keeps every texture below 2048 px while reconstructing the source plate
	# pixel-for-pixel at runtime. Foreground crops still use original plate space.
	var root := Node2D.new()
	root.name = "BackgroundPlate"
	add_child(root)
	var source_size := _vector(_manifest["source_resolution"])
	var sprite_scale := _vector(_manifest["sprite_scale"])
	var background_centre := _vector(_manifest["background_centre"])
	var tile_size := source_size * 0.5
	for row: int in range(2):
		for column: int in range(2):
			var sprite := Sprite2D.new()
			sprite.name = "Tile_%d_%d" % [row, column]
			sprite.texture = load(ASSET_ROOT + "frozen_coast_phase_a_background_r%d_c%d.png" % [row, column]) as Texture2D
			var crop_centre := Vector2((column + 0.5) * tile_size.x, (row + 0.5) * tile_size.y)
			sprite.position = background_centre + (crop_centre - source_size * 0.5) * sprite_scale
			sprite.scale = sprite_scale
			root.add_child(sprite)

func _build_occluders() -> void:
	if actor_layer == null:
		push_error("Frozen Coast visuals require the existing Actors Node2D")
		return
	actor_layer.y_sort_enabled = true
	var source_size := _vector(_manifest["source_resolution"])
	var sprite_scale := _vector(_manifest["sprite_scale"])
	var background_centre := _vector(_manifest["background_centre"])
	var layers: Dictionary = _manifest["layers"]
	for layer_name: String in layers:
		var layer: Dictionary = layers[layer_name]
		var crop: Array = layer["crop"]
		var crop_centre := Vector2(
			(float(crop[0]) + float(crop[2])) * 0.5,
			(float(crop[1]) + float(crop[3])) * 0.5
		)
		var visual_centre := background_centre + (crop_centre - source_size * 0.5) * sprite_scale
		var sort_baseline: float = float(layer["sort_baseline"])

		var sort_root := Node2D.new()
		sort_root.name = "FrozenCoastOccluder_%s" % layer_name.to_pascal_case()
		sort_root.position = Vector2(0.0, sort_baseline)
		sort_root.set_meta(&"frozen_coast_visual_layer", StringName(layer_name))
		actor_layer.add_child(sort_root)
		_actor_occluders.append(sort_root)

		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = load(ASSET_ROOT + str(layer["file"])) as Texture2D
		sprite.position = visual_centre - sort_root.position
		sprite.scale = sprite_scale
		if str(layer.get("kind", "")) == "plateau_rim_occluder":
			sprite.modulate.a = RIM_ALPHA
		sort_root.add_child(sprite)

func _build_collision() -> void:
	var godot: Dictionary = _guides.get("godot", {})
	var boundary: Dictionary = godot.get("walk_boundary", {})
	_build_boundary(boundary)

	var hard: Dictionary = godot.get("hard", {})
	for object_name: String in hard:
		var data: Dictionary = hard[object_name]
		if data.has("poly"):
			_build_polygon_body(object_name, data["poly"], object_name == "rib_south_wedge_fill")
		elif data.has("polyline"):
			_build_capsule_chain(object_name, data["polyline"], float(data.get("radius_godot", 17.6)))

func _build_boundary(boundary: Dictionary) -> void:
	var raw_points: Array = boundary.get("pts", [])
	var labels: Array = boundary.get("lbl", [])
	if raw_points.size() < 3 or labels.size() != raw_points.size():
		push_error("Frozen Coast walk boundary is incomplete")
		return
	var body := StaticBody2D.new()
	body.name = "WalkBoundary"
	add_child(body)
	_hard_bodies.append(body)
	for index: int in range(raw_points.size()):
		var next_index := (index + 1) % raw_points.size()
		if str(labels[index]) == "transition" and str(labels[next_index]) == "transition":
			continue
		var shape := SegmentShape2D.new()
		shape.a = _vector(raw_points[index])
		shape.b = _vector(raw_points[next_index])
		var collision := CollisionShape2D.new()
		collision.name = "Edge_%02d_%s" % [index, str(labels[index]).to_pascal_case()]
		collision.shape = shape
		body.add_child(collision)

func _build_polygon_body(object_name: String, raw_points: Array, no_stun: bool) -> void:
	if raw_points.size() < 3:
		return
	var body := StaticBody2D.new()
	body.name = object_name.to_pascal_case()
	if no_stun:
		body.add_to_group(NO_STUN_GROUP)
	add_child(body)
	_hard_bodies.append(body)
	var shape := ConvexPolygonShape2D.new()
	shape.points = _packed_points(raw_points)
	var collision := CollisionShape2D.new()
	collision.name = "Collision"
	collision.shape = shape
	body.add_child(collision)

func _build_capsule_chain(object_name: String, raw_points: Array, radius: float) -> void:
	if raw_points.size() < 2:
		return
	var body := StaticBody2D.new()
	body.name = object_name.to_pascal_case()
	add_child(body)
	_hard_bodies.append(body)
	for index: int in range(raw_points.size() - 1):
		var a := _vector(raw_points[index])
		var b := _vector(raw_points[index + 1])
		var delta := b - a
		var shape := CapsuleShape2D.new()
		shape.radius = radius
		shape.height = delta.length() + radius * 2.0
		var collision := CollisionShape2D.new()
		collision.name = "Segment_%02d" % index
		collision.position = (a + b) * 0.5
		collision.rotation = delta.angle() - PI * 0.5
		collision.shape = shape
		body.add_child(collision)

func _build_soft_zones() -> void:
	var godot: Dictionary = _guides.get("godot", {})
	var soft: Dictionary = godot.get("soft", {})
	for zone_name: String in soft:
		var data: Dictionary = soft[zone_name]
		var raw_points: Array = data.get("poly", [])
		if raw_points.size() < 3:
			continue
		var area := Area2D.new()
		area.name = "Soft_%s" % zone_name.to_pascal_case()
		area.collision_layer = 0
		area.collision_mask = ENEMY_PHYSICS_LAYER_MASK
		area.monitoring = true
		area.monitorable = false
		area.set_meta(&"soft_terrain_id", StringName(zone_name))
		var polygon := CollisionPolygon2D.new()
		polygon.name = "Collision"
		polygon.polygon = _packed_points(raw_points)
		area.add_child(polygon)
		add_child(area)
		_soft_zones.append(area)

func _soft_drift_behavior(body: Node2D) -> ChargeBehavior:
	if body is not ArenaEnemy:
		return null
	var charge := (body as ArenaEnemy).behavior as ChargeBehavior
	if charge == null or not charge.crash_on_world_collision or is_equal_approx(charge.soft_charge_speed_multiplier, 1.0):
		return null
	return charge

func _exit_tree() -> void:
	for behavior: Variant in _soft_drift_behaviors:
		if not is_instance_valid(behavior):
			continue
		(behavior as ChargeBehavior).set_soft_charge_active(false)
	_soft_drift_behaviors.clear()
	for occluder: Node2D in _actor_occluders:
		if is_instance_valid(occluder):
			occluder.queue_free()
	_actor_occluders.clear()
	if is_instance_valid(actor_layer):
		actor_layer.y_sort_enabled = false

static func _packed_points(raw_points: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for raw: Variant in raw_points:
		points.append(_vector(raw))
	return points

static func _vector(value: Variant) -> Vector2:
	var parts: Array = value as Array
	return Vector2(float(parts[0]), float(parts[1]))
