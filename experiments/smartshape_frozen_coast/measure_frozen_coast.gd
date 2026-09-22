extends SceneTree
## EXPERIMENT — rough cost comparison against today's rectangular arena. Uses
## the real renderer; do not run with --headless.
##
##   xvfb-run -a godot --path . --display-driver x11 --rendering-driver opengl3 \
##     --script res://experiments/smartshape_frozen_coast/measure_frozen_coast.gd
##
## This runs Compatibility (the renderer the Android build uses) on a software
## rasteriser, so absolute milliseconds say nothing about a phone. Counts —
## draw calls, primitives, objects, bytes — and the difference between the two
## scenes are what carry over.

const SCENES := {
	"rectangular arena": "res://scenes/arena/test_arena.tscn",
	"frozen coast": "res://experiments/smartshape_frozen_coast/frozen_coast.tscn",
}

func _initialize() -> void:
	call_deferred("_run")

func _hold_still(run: Node) -> void:
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

func _average(monitor: Performance.Monitor, frames: int) -> float:
	var total: float = 0.0
	for frame: int in range(frames):
		await process_frame
		total += Performance.get_monitor(monitor)
	return total / frames

func _profile(label: String, path: String, hide_terrain: bool = false) -> void:
	var loads := PackedFloat64Array()
	for attempt: int in range(5):
		var started: int = Time.get_ticks_usec()
		var packed := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as PackedScene
		loads.append((Time.get_ticks_usec() - started) / 1000.0)
		packed = null
	var packed_scene := load(path) as PackedScene
	var begin: int = Time.get_ticks_usec()
	var run := packed_scene.instantiate()
	run.set("player_count", 4)
	var instanced: float = (Time.get_ticks_usec() - begin) / 1000.0
	begin = Time.get_ticks_usec()
	root.add_child(run)
	var entered: float = (Time.get_ticks_usec() - begin) / 1000.0
	var first_frames := PackedFloat64Array()
	for frame: int in range(8):
		var tick: int = Time.get_ticks_usec()
		await process_frame
		first_frames.append((Time.get_ticks_usec() - tick) / 1000.0)
	_hold_still(run)
	if hide_terrain and run.has_node("Terrain"):
		run.get_node("Terrain").visible = false
	for frame: int in range(30):
		await process_frame
	var calls: float = await _average(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME, 60)
	var primitives: float = await _average(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME, 60)
	var objects: float = await _average(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME, 60)
	var process_ms: float = await _average(Performance.TIME_PROCESS, 60)
	loads.sort()
	print("PERF [%s]" % label)
	print("  load PackedScene, median of 5 (ms)   %.2f" % loads[2])
	print("  instantiate (ms)                     %.2f" % instanced)
	print("  add_child incl. _ready (ms)          %.2f" % entered)
	print("  first 8 frame times (ms)             %s" % str(Array(first_frames).map(func(v: float) -> float: return snappedf(v, 0.1))))
	print("  draw calls / frame                   %.1f" % calls)
	print("  primitives / frame                   %.1f" % primitives)
	print("  render objects / frame               %.1f" % objects)
	print("  process time (ms)                    %.3f" % (process_ms * 1000.0))
	print("  nodes in tree                        %d" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("  resources alive                      %d" % Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	print("  video memory used (KiB)              %.0f" % (Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1024.0))
	run.queue_free()
	for frame: int in range(5):
		await process_frame

func _run() -> void:
	# Warm the shader cache once so neither scene pays first-compile costs.
	var warm := (load(SCENES["frozen coast"]) as PackedScene).instantiate()
	root.add_child(warm)
	for frame: int in range(10):
		await process_frame
	warm.queue_free()
	for frame: int in range(5):
		await process_frame
	await _profile("rectangular arena", SCENES["rectangular arena"])
	await _profile("frozen coast", SCENES["frozen coast"])
	await _profile("frozen coast, SmartShape terrain hidden", SCENES["frozen coast"], true)
	var text := FileAccess.get_file_as_string(SCENES["frozen coast"])
	print("SCENE FILE [frozen coast]  %d bytes, %d lines, %d sub_resources, %d ArrayMesh blobs" % [text.length(), text.count("\n"), text.count("[sub_resource"), text.count("type=\"ArrayMesh\"")])
	var arena_text := FileAccess.get_file_as_string(SCENES["rectangular arena"])
	print("SCENE FILE [rectangular arena]  %d bytes, %d lines, %d sub_resources" % [arena_text.length(), arena_text.count("\n"), arena_text.count("[sub_resource")])
	print("MEASURE DONE")
	quit(0)
