extends SceneTree
## EXPERIMENT — real-renderer captures for the SmartShape2D spike. Uses the real
## renderer; do not run with --headless.
##
##   xvfb-run -a godot --path . --display-driver x11 --rendering-driver opengl3 \
##     --script res://experiments/smartshape_frozen_coast/capture_frozen_coast.gd
##
## Writes docs/smartshape-frozen-coast-runtime.png, -collision.png and
## -comparison.png.

const SCENE := "res://experiments/smartshape_frozen_coast/frozen_coast.tscn"
const ARENA := "res://scenes/arena/test_arena.tscn"
var failures: int = 0

## Draws the two geography answers on top of the room: the RoomDefinition clamp
## that actually governs movement, and the coastline SmartShape can bake. The
## red wash is the difference — ground the rules let you walk on that the art
## says is sea.
class AuthorityOverlay extends Node2D:
	var bounds: Rect2
	var coast: PackedVector2Array
	var threshold: Rect2

	func _draw() -> void:
		var rect := PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)])
		for sea: PackedVector2Array in Geometry2D.clip_polygons(rect, coast):
			if not Geometry2D.is_polygon_clockwise(sea) or sea.size() > 2:
				draw_colored_polygon(sea, Color(1.0, 0.25, 0.3, 0.32))
		draw_rect(bounds, Color("ffd24a"), false, 4.0)
		var closed := coast.duplicate()
		closed.append(coast[0])
		draw_polyline(closed, Color("ff4fd8"), 3.0)
		draw_rect(threshold, Color("5dffa0"), false, 3.0)
		var font: Font = ThemeDB.fallback_font
		draw_rect(Rect2(bounds.position + Vector2(14, 12), Vector2(560, 88)), Color(0.02, 0.07, 0.12, 0.82))
		draw_string(font, bounds.position + Vector2(24, 36), "RoomDefinition.bounds  (authoritative movement clamp)", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ffd24a"))
		draw_string(font, bounds.position + Vector2(24, 62), "SmartShape-baked coastline collision  (shipped inert)", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ff4fd8"))
		draw_string(font, bounds.position + Vector2(24, 88), "Red: walkable under today's rules, drawn as sea", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.45, 0.5))
		draw_string(font, threshold.position + Vector2(-150, -10), "PartyGate threshold", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("5dffa0"))

func _initialize() -> void:
	call_deferred("_run")

func _grab() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _write(image: Image, path: String) -> void:
	if image.save_png(path) != OK:
		failures += 1
		push_error("FAIL: could not write " + path)

## Freeze the actors so a capture shows the room, not a fight in progress.
func _hold_still(run: Node2D) -> void:
	for node: Node in run.get_node("Actors").get_children():
		node.set_physics_process(false)
		if node is PenguinPlayer:
			for slot: int in range(node.weapon_rack.capacity()):
				var controller: WeaponController = node.weapon_rack.controller_at(slot)
				if controller != null:
					controller.set_physics_process(false)
	var encounter: Node = run.get_node_or_null("Encounter")
	if encounter != null:
		encounter.set_physics_process(false)

func _caption(run: Node, text: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	var label := Label.new()
	label.text = text
	label.position = Vector2(330, 660)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color("06121c"))
	label.add_theme_constant_override("outline_size", 8)
	layer.add_child(label)
	run.add_child(layer)

func _frozen_coast() -> Node2D:
	var run := (load(SCENE) as PackedScene).instantiate() as Node2D
	run.player_count = 4
	root.add_child(run)
	for frame: int in range(10):
		await process_frame
	_hold_still(run)
	# Two penguins in the clearing, two heading down the passage to the doorway,
	# and a pair of seals for scale. Placement is for the picture only.
	var players: Array[PenguinPlayer] = run.party.members()
	var spots: Array[Vector2] = [Vector2(-360, -40), Vector2(-280, 30), Vector2(360, -20), Vector2(450, 30)]
	for index: int in range(players.size()):
		players[index].position = spots[index]
	for at: Vector2 in [Vector2(-60, 160), Vector2(40, -120)]:
		var seal := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as ArenaEnemy
		seal.party = run.party
		seal.position = at
		run.get_node("Actors").add_child(seal)
		seal.set_physics_process(false)
	for frame: int in range(30):
		await process_frame
	return run

func _run() -> void:
	# 1. The room as a player sees it.
	var run: Node2D = await _frozen_coast()
	_write(await _grab(), "res://docs/smartshape-frozen-coast-runtime.png")

	# 2. The same frame with both geography answers drawn over it.
	var overlay := AuthorityOverlay.new()
	overlay.z_index = 50
	overlay.bounds = run.room.bounds
	var polygon := run.get_node("Terrain/ShelfCollision/Polygon") as CollisionPolygon2D
	overlay.coast = polygon.global_transform * polygon.polygon
	var gate: PartyGate = run.gates()[0]
	overlay.threshold = Rect2(gate.global_position + gate.threshold.position, gate.threshold.size)
	run.add_child(overlay)
	# A diagnostic picture: the corner cards would sit on top of the legend.
	run.get_node("HUD").visible = false
	for frame: int in range(3):
		await process_frame
	_write(await _grab(), "res://docs/smartshape-frozen-coast-collision.png")
	overlay.queue_free()
	run.get_node("HUD").visible = true

	# 3. Today's rectangular language above the SmartShape coast.
	_caption(run, "SMARTSHAPE FROZEN COAST  (prototype)")
	for frame: int in range(3):
		await process_frame
	var coast_shot: Image = await _grab()
	run.queue_free()
	for frame: int in range(3):
		await process_frame
	var arena := (load(ARENA) as PackedScene).instantiate() as Node2D
	arena.player_count = 4
	root.add_child(arena)
	for frame: int in range(10):
		await process_frame
	_hold_still(arena)
	_caption(arena, "CURRENT RECTANGULAR LANGUAGE  (Frostfall Bay)")
	for frame: int in range(30):
		await process_frame
	var arena_shot: Image = await _grab()
	var both := Image.create(arena_shot.get_width(), arena_shot.get_height() * 2, false, arena_shot.get_format())
	both.blit_rect(arena_shot, Rect2i(Vector2i.ZERO, arena_shot.get_size()), Vector2i.ZERO)
	both.blit_rect(coast_shot, Rect2i(Vector2i.ZERO, coast_shot.get_size()), Vector2i(0, arena_shot.get_height()))
	_write(both, "res://docs/smartshape-frozen-coast-comparison.png")

	print("FROZEN COAST CAPTURE: ", "PASS" if failures == 0 else "FAIL", " (%d failures)" % failures)
	quit(0 if failures == 0 else 1)
