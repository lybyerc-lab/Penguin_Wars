class_name TownshipVisualV1
extends Node2D
## Township-specific presentation adapter for the approved Blender V0.1.1
## environment. Gameplay remains in the existing Node2D world; this node adds
## one baked background and a small set of y-sorted occlusion sprites.

const ASSET_ROOT := "res://assets/environments/township_visual_v1/"
const MANIFEST_PATH := ASSET_ROOT + "township_visual_manifest.json"
const BACKGROUND_CENTRE := Vector2(0.0, 200.0)

const SORT_BASELINES := {
	"great_hall": -543.0,
	"workshop": -161.0,
	"nurse_hut": 614.0,
	"home_b": 867.0,
	"fishers_stall": -52.0,
	"fish_shed": -84.0,
	"net_shed": 376.0,
	"expedition_lodge": 919.0,
	"gate_bell": 917.0,
	"slide_foreground": 390.0,
}

var actor_layer: Node2D
var _actor_occluders: Array[Node2D] = []

static func build(into: Node2D, actors: Node2D) -> TownshipVisualV1:
	var visual := TownshipVisualV1.new()
	visual.name = "TownshipVisualV1"
	visual.actor_layer = actors
	into.add_child(visual)
	return visual

func _ready() -> void:
	z_index = -8
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var manifest := _load_manifest()
	if manifest.is_empty():
		return
	_build_background(manifest)
	_build_occluders(manifest)

func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_error("Township visual manifest is missing: %s" % MANIFEST_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if parsed is not Dictionary:
		push_error("Township visual manifest is invalid JSON")
		return {}
	return parsed as Dictionary

func _build_background(manifest: Dictionary) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "BackgroundPlate"
	sprite.texture = load(ASSET_ROOT + str(manifest["background"])) as Texture2D
	sprite.position = BACKGROUND_CENTRE
	sprite.scale = _vector(manifest["sprite_scale"])
	add_child(sprite)

func _build_occluders(manifest: Dictionary) -> void:
	if actor_layer == null:
		push_error("Township visuals require the existing Actors Node2D")
		return
	actor_layer.y_sort_enabled = true
	var source_size := _vector(manifest["source_resolution"])
	var sprite_scale := _vector(manifest["sprite_scale"])
	var layers: Dictionary = manifest["layers"]
	for layer_name: String in SORT_BASELINES:
		if not layers.has(layer_name):
			push_error("Township visual layer is missing: %s" % layer_name)
			continue
		var layer: Dictionary = layers[layer_name]
		var crop: Array = layer["crop"]
		var crop_centre := Vector2(
			(float(crop[0]) + float(crop[2])) * 0.5,
			(float(crop[1]) + float(crop[3])) * 0.5
		)
		var visual_centre := BACKGROUND_CENTRE + (crop_centre - source_size * 0.5) * sprite_scale

		var sort_root := Node2D.new()
		sort_root.name = "TownshipOccluder_%s" % layer_name.to_pascal_case()
		sort_root.position = Vector2(0.0, float(SORT_BASELINES[layer_name]))
		sort_root.set_meta(&"township_visual_layer", layer_name)
		actor_layer.add_child(sort_root)
		_actor_occluders.append(sort_root)

		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = load(ASSET_ROOT + str(layer["file"])) as Texture2D
		sprite.position = visual_centre - sort_root.position
		sprite.scale = sprite_scale
		sort_root.add_child(sprite)

func _exit_tree() -> void:
	for occluder: Node2D in _actor_occluders:
		if is_instance_valid(occluder):
			occluder.queue_free()
	_actor_occluders.clear()
	if is_instance_valid(actor_layer):
		actor_layer.y_sort_enabled = false

static func _vector(value: Variant) -> Vector2:
	var parts: Array = value as Array
	return Vector2(float(parts[0]), float(parts[1]))
