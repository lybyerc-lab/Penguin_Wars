@tool
extends EditorPlugin
## EXPERIMENT — removability probe. Opens the Frozen Coast prototype in the
## editor in whatever state SmartShape is in (plugin disabled, or the addon
## folder deleted), reports what survived, captures the editor, and quits.
## Uses no SmartShape identifiers, so it still parses when the addon is gone.
## Inert unless launched with `-- --ss2d-eval-open [--probe-shot=PATH]`.

const SCENE := "res://experiments/smartshape_frozen_coast/frozen_coast.tscn"

func _enter_tree() -> void:
	if "--ss2d-eval-open" in OS.get_cmdline_user_args():
		_probe.call_deferred()

func _log(key: String, value: Variant) -> void:
	print("PROBE: %s = %s" % [key, str(value)])

func _frames(count: int) -> void:
	for index: int in range(count):
		await get_tree().process_frame

func _probe() -> void:
	OS.low_processor_usage_mode = false
	await _frames(120)
	EditorInterface.open_scene_from_path(SCENE)
	await _frames(40)
	EditorInterface.set_main_screen_editor("2D")
	var root := EditorInterface.get_edited_scene_root()
	_log("scene opened in editor", root != null and root.scene_file_path == SCENE)
	if root != null:
		var shelf: Node = root.get_node_or_null("Terrain/Shelf")
		_log("Shelf node class", shelf.get_class() if shelf != null else "missing")
		_log("Shelf script", shelf.get_script().resource_path if shelf != null and shelf.get_script() != null else "none")
		var polygon := root.get_node_or_null("Terrain/ShelfCollision/Polygon") as CollisionPolygon2D
		_log("baked collision vertices", polygon.polygon.size() if polygon != null else -1)
		if shelf != null:
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(shelf)
			EditorInterface.edit_node(shelf)
		for node: Node in EditorInterface.get_base_control().find_children("*", "", true, false):
			if node.get_class() == "EditorZoomWidget" and node.is_visible_in_tree():
				node.call("set_zoom", 0.55)
				node.emit_signal("zoom_changed", 0.55)
				break
		await _frames(10)
		await RenderingServer.frame_post_draw
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--probe-shot="):
				get_tree().root.get_texture().get_image().save_png(arg.substr(13))
	_log("complete", true)
	get_tree().quit(0)
