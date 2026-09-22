@tool
extends EditorPlugin
## EXPERIMENT — drives one real Godot editor session against the Frozen Coast
## prototype through SmartShape's own input handling, then quits. It does
## nothing unless the editor was launched with `-- --ss2d-eval-session`, so
## enabling it by accident is harmless. Not committed as enabled.
##
## Mouse gestures are fed to SmartShape's `_forward_canvas_gui_input`, the same
## entry point the 2D editor calls for a real click, so edge splitting, dragging
## and undo go through upstream's code rather than a shortcut around it.

const SCENE := "res://experiments/smartshape_frozen_coast/frozen_coast.tscn"
const SCRATCH := "res://experiments/smartshape_frozen_coast/_scratch_duplicate.tscn"
const SHOT := "res://docs/smartshape-frozen-coast-editor.png"

var _ss2d: EditorPlugin

func _enter_tree() -> void:
	if not "--ss2d-eval-session" in OS.get_cmdline_user_args():
		return
	_session.call_deferred()

func _log(key: String, value: Variant) -> void:
	print("SESSION: %s = %s" % [key, str(value)])

func _frames(count: int) -> void:
	for index: int in range(count):
		await get_tree().process_frame

func _find_ss2d() -> EditorPlugin:
	for node: Node in get_tree().root.find_children("*", "EditorPlugin", true, false):
		if node is SS2D_Plugin:
			return node
	return null

func _et() -> Transform2D:
	return EditorInterface.get_edited_scene_root().get_viewport().global_canvas_transform

func _screen(shape: SS2D_Shape, local: Vector2) -> Vector2:
	return (_et() * shape.get_global_transform()) * local

func _select(node: Node) -> void:
	var selection := EditorInterface.get_selection()
	selection.clear()
	selection.add_node(node)
	EditorInterface.edit_node(node)
	await _frames(6)

func _send(event: InputEvent) -> bool:
	var used: bool = _ss2d._forward_canvas_gui_input(event)
	_ss2d.update_overlays()
	await _frames(3)
	return used

func _motion(at: Vector2, held: bool) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	return event

func _button(at: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	return event

## Hover, press, drag, release — one author gesture.
func _drag(from: Vector2, to: Vector2) -> void:
	await _send(_motion(from, false))
	await _send(_button(from, true))
	var steps: int = 6
	for step: int in range(1, steps + 1):
		await _send(_motion(from.lerp(to, float(step) / steps), true))
	await _send(_button(to, false))

func _history() -> UndoRedo:
	var manager := get_undo_redo()
	var root := EditorInterface.get_edited_scene_root()
	return manager.get_history_undo_redo(manager.get_object_history_id(root))

func _positions(shape: SS2D_Shape) -> PackedVector2Array:
	var result := PackedVector2Array()
	var points := shape.get_point_array()
	for index: int in range(points.get_point_count()):
		result.append(points.get_point_position(points.get_point_key_at_index(index)))
	return result

func _frame_room() -> void:
	# Fit the whole room into the 2D view so the capture shows the authoring
	# context, not a corner of it. The 2D editor owns its view transform, so go
	# through its zoom widget and "Frame Selection" rather than overwriting it.
	for node: Node in EditorInterface.get_base_control().find_children("*", "", true, false):
		if node.get_class() == "EditorZoomWidget" and node.is_visible_in_tree():
			node.call("set_zoom", 0.55)
			node.emit_signal("zoom_changed", 0.55)
			break
	await _frames(4)
	var frame := InputEventKey.new()
	frame.keycode = KEY_F
	frame.physical_keycode = KEY_F
	frame.pressed = true
	EditorInterface.get_editor_viewport_2d().get_parent().grab_focus()
	Input.parse_input_event(frame)
	await _frames(2)
	frame = frame.duplicate()
	frame.pressed = false
	Input.parse_input_event(frame)
	await _frames(6)
	_log("editor 2D zoom after framing", snappedf(_et().get_scale().x, 0.01))

func _session() -> void:
	# The editor normally redraws only when something changes; a scripted
	# session needs every frame drawn or frame_post_draw never arrives.
	OS.low_processor_usage_mode = false
	await _frames(120)
	var pristine_text := FileAccess.get_file_as_string(SCENE)
	EditorInterface.open_scene_from_path(SCENE)
	await _frames(40)
	EditorInterface.set_main_screen_editor("2D")
	await _frames(10)
	var root := EditorInterface.get_edited_scene_root()
	_log("scene opened", root != null and root.scene_file_path == SCENE)
	_ss2d = _find_ss2d()
	_log("SmartShape plugin active", _ss2d != null)
	if _ss2d == null or root == null:
		get_tree().quit(1)
		return
	var shelf := root.get_node("Terrain/Shelf") as SS2D_Shape
	var polygon := root.get_node("Terrain/ShelfCollision/Polygon") as CollisionPolygon2D

	# ---- The required editor capture: Shelf selected, control points showing.
	await _select(shelf)
	_log("progress", "shelf selected")
	await _frame_room()
	_log("progress", "room framed")
	_ss2d.update_overlays()
	await _frames(6)
	await RenderingServer.frame_post_draw
	_log("editor capture written", get_tree().root.get_texture().get_image().save_png(SHOT) == OK)

	# ---- Cost of one rebuild in the editor, which is what dragging pays.
	var started: int = Time.get_ticks_usec()
	for pass_index: int in range(10):
		shelf._build_meshes()
		shelf.bake_collision()
	_log("editor rebuild+bake of Shelf, mean ms", snappedf((Time.get_ticks_usec() - started) / 10000.0, 0.01))

	# ---- Split an edge and drag the new point, as an author would.
	var before: PackedVector2Array = _positions(shelf)
	var polygon_before: int = polygon.polygon.size()
	var tessellated := shelf.get_point_array().get_tessellated_points()
	var target: Vector2 = tessellated[0]
	for point: Vector2 in tessellated:
		if point.distance_to(Vector2(-220, -292)) < target.distance_to(Vector2(-220, -292)):
			target = point
	var grip: Vector2 = _screen(shelf, target)
	await _drag(grip, grip + Vector2(0, -34))
	var after: PackedVector2Array = _positions(shelf)
	_log("points before gesture", before.size())
	_log("points after split+drag", after.size())
	_log("collision vertices before / after gesture (editor rebakes)", "%d / %d" % [polygon_before, polygon.polygon.size()])
	var history := _history()
	_log("undo history entries created by gesture", history.get_history_count())
	history.undo()
	history.undo()
	await _frames(4)
	_log("after 2x undo, geometry equals original", _positions(shelf) == before)
	_log("after 2x undo, collision vertices", polygon.polygon.size())
	history.redo()
	history.redo()
	await _frames(4)
	_log("after 2x redo, geometry equals edited", _positions(shelf) == after)
	history.undo()
	history.undo()
	await _frames(4)

	# ---- The duplicated-shape trap, deliberately.
	var floe := root.get_node("Terrain/Floe1") as SS2D_Shape
	var copy := floe.duplicate() as SS2D_Shape
	copy.name = "Floe1Copy"
	floe.get_parent().add_child(copy)
	copy.owner = root
	copy.position = floe.position + Vector2(-190, 30)
	await _frames(6)
	_log("duplicate shares the SS2D_Point_Array", copy.get_point_array() == floe.get_point_array())
	_log("duplicate shares the mesh cache (fixed upstream in #208)", copy._mesh_cache == floe._mesh_cache)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, SCRATCH)
	var scratch := FileAccess.get_file_as_string(SCRATCH)
	var original_ref: String = _points_reference(scratch, "Floe1")
	var copy_ref: String = _points_reference(scratch, "Floe1Copy")
	_log("saved scene: Floe1 _points reference", original_ref)
	_log("saved scene: Floe1Copy _points reference", copy_ref)
	_log("saved scene: both nodes point at ONE sub-resource", original_ref != "" and original_ref == copy_ref)
	# Compare whole point arrays, not one vertex: a gesture that lands on a
	# handle or an edge changes different points, and all of them count.
	var original_before: PackedVector2Array = _positions(floe)
	var copy_before: PackedVector2Array = _positions(copy)
	await _select(copy)
	var vertex: Vector2 = _screen(copy, copy.get_point_array().get_point_position(copy.get_point_array().get_point_key_at_index(1)))
	await _drag(vertex, vertex + Vector2(30, 0))
	_log("the author's drag changed the COPY", _positions(copy) != copy_before)
	_log("editing the COPY moved the ORIGINAL (the trap)", _positions(floe) != original_before)
	# The inspector button opens a confirmation dialog; the action only runs on
	# OK. Press OK the way a user would.
	copy._make_unique_action("pressed")
	await _frames(4)
	_log("Make Unique asks for confirmation first", _ss2d.make_unique_dialog.visible)
	_ss2d.make_unique_dialog.get_ok_button().pressed.emit()
	await _frames(4)
	_log("after Make Unique, shares the point array", copy.get_point_array() == floe.get_point_array())
	var settled: PackedVector2Array = _positions(floe)
	var unique_before: PackedVector2Array = _positions(copy)
	vertex = _screen(copy, copy.get_point_array().get_point_position(copy.get_point_array().get_point_key_at_index(1)))
	await _drag(vertex, vertex + Vector2(30, 0))
	_log("after Make Unique, the author's drag changed the copy", _positions(copy) != unique_before)
	_log("after Make Unique, editing the copy leaves the original alone", _positions(floe) == settled)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))

	# ---- Save behaviour on a pristine reload: churn and stability.
	EditorInterface.reload_scene_from_path(SCENE)
	await _frames(30)
	root = EditorInterface.get_edited_scene_root()
	var reloaded := root.get_node("Terrain/Shelf") as SS2D_Shape
	_log("reload restores original geometry", _positions(reloaded) == before)
	EditorInterface.mark_scene_as_unsaved()
	EditorInterface.save_scene()
	await _frames(20)
	var first_save := FileAccess.get_file_as_string(SCENE)
	_log("editor re-save vs builder output, changed lines", _changed_lines(pristine_text, first_save))
	EditorInterface.mark_scene_as_unsaved()
	EditorInterface.save_scene()
	await _frames(20)
	var second_save := FileAccess.get_file_as_string(SCENE)
	_log("second editor save with no edits, changed lines", _changed_lines(first_save, second_save))

	# ---- What one ordinary edit costs in version control.
	var shelf_again := root.get_node("Terrain/Shelf") as SS2D_Shape
	await _select(shelf_again)
	var points := shelf_again.get_point_array()
	var nudge: Vector2 = _screen(shelf_again, points.get_point_position(points.get_point_key_at_index(6)))
	await _drag(nudge, nudge + Vector2(10, 0))
	EditorInterface.save_scene()
	await _frames(20)
	var edited_save := FileAccess.get_file_as_string(SCENE)
	_log("one vertex nudged 10px: changed lines in .tscn", _changed_lines(second_save, edited_save))
	_log("one vertex nudged 10px: changed bytes in .tscn", _changed_bytes(second_save, edited_save))
	_history().undo()
	await _frames(6)
	EditorInterface.save_scene()
	await _frames(20)
	_log("undo + save restores the file byte-for-byte", FileAccess.get_file_as_string(SCENE) == second_save)
	_log("session complete", true)
	get_tree().quit(0)

func _changed_lines(a: String, b: String) -> int:
	var left := a.split("\n")
	var right := b.split("\n")
	var changed: int = absi(left.size() - right.size())
	for index: int in range(mini(left.size(), right.size())):
		if left[index] != right[index]:
			changed += 1
	return changed

## The SubResource id a node's `_points` property refers to in a saved scene.
func _points_reference(text: String, node_name: String) -> String:
	var start: int = text.find("[node name=\"%s\"" % node_name)
	if start < 0:
		return ""
	var stop: int = text.find("\n[", start + 1)
	var block: String = text.substr(start, (stop - start) if stop > 0 else -1)
	var at: int = block.find("_points = ")
	if at < 0:
		return ""
	return block.substr(at + 10, block.find("\n", at) - at - 10)

func _changed_bytes(a: String, b: String) -> int:
	var left := a.split("\n")
	var right := b.split("\n")
	var total: int = 0
	for index: int in range(maxi(left.size(), right.size())):
		var x: String = left[index] if index < left.size() else ""
		var y: String = right[index] if index < right.size() else ""
		if x != y:
			total += maxi(x.length(), y.length())
	return total
