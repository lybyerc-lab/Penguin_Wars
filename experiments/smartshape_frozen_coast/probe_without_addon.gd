extends SceneTree
## EXPERIMENT — what a shipped room looks like if the SmartShape addon folder
## is deleted. Uses no SmartShape identifiers so it runs either way.
##
##   godot --headless --path . --script res://experiments/smartshape_frozen_coast/probe_without_addon.gd

const SCENE := "res://experiments/smartshape_frozen_coast/frozen_coast.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _log(key: String, value: Variant) -> void:
	print("PROBE: %s = %s" % [key, str(value)])

func _run() -> void:
	var packed := ResourceLoader.load(SCENE, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as PackedScene
	_log("PackedScene loaded", packed != null)
	if packed == null:
		quit(0)
		return
	var run := packed.instantiate()
	_log("instantiated", run != null)
	var terrain: Node = run.get_node_or_null("Terrain")
	for child: Node in terrain.get_children() if terrain != null else []:
		var script: Script = child.get_script()
		_log("Terrain/%s" % child.name, "%s, script=%s, meta=%s" % [child.get_class(), script.resource_path if script != null else "none", str(child.get_meta_list())])
	var polygon := run.get_node_or_null("Terrain/ShelfCollision/Polygon") as CollisionPolygon2D
	_log("baked collision vertices", polygon.polygon.size() if polygon != null else -1)
	# The hazard: what does re-saving this scene keep?
	var repacked := PackedScene.new()
	var result: Error = repacked.pack(run)
	var path := "user://frozen_coast_resaved_without_addon.tscn"
	if result == OK:
		result = ResourceSaver.save(repacked, path)
	var text := FileAccess.get_file_as_string(path) if result == OK else ""
	_log("re-save without addon succeeded", result == OK)
	_log("re-saved file still has point data", text.contains("point_in"))
	_log("re-saved file still has baked meshes", text.contains("ArrayMesh"))
	_log("re-saved file still has collision polygon", text.contains("polygon = PackedVector2Array"))
	_log("re-saved file size vs original", "%d vs %d bytes" % [text.length(), FileAccess.get_file_as_string(SCENE).length()])
	if DisplayServer.get_name() != "headless":
		# With a real renderer, show what the room looks like now.
		run.set("player_count", 2)
		root.add_child(run)
		for frame: int in range(40):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://frozen_coast_without_addon.png")
		_log("runtime capture written", ProjectSettings.globalize_path("user://frozen_coast_without_addon.png"))
		run.queue_free()
		await process_frame
	else:
		run.free()
	quit(0)
