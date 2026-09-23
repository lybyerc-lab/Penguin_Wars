extends SceneTree
## Tool script to generate temporary diagnostic test fixtures for the Penguin Wars
## character animation import contract.
## Generates two synchronized layers under tests/fixtures/character_animation/:
## 1. base/<state>/penguin_<state>_###.png (Penguin body, belly, beak, feet - no colorized scarf)
## 2. scarf/<state>/penguin_<state>_###.png (Neutral/white scarf overlay on transparent background)
## Clearly marked as TEMPORARY TEST FIXTURE.

const Contract = preload("res://scripts/data/character_animation_contract.gd")

const STATES = {
	"idle": {"count": 4, "base_color": Color(0.12, 0.16, 0.22, 0.95)},
	"move": {"count": 8, "base_color": Color(0.12, 0.16, 0.22, 0.95)},
	"dash": {"count": 4, "base_color": Color(0.15, 0.20, 0.28, 0.95)},
	"hit": {"count": 6, "base_color": Color(0.35, 0.15, 0.18, 0.95)},
	"downed": {"count": 6, "base_color": Color(0.18, 0.14, 0.24, 0.95)},
	"revive": {"count": 6, "base_color": Color(0.14, 0.22, 0.20, 0.95)},
}

func _initialize() -> void:
	print("Generating diagnostic animation fixtures under %s..." % Contract.PATH_FIXTURE_ROOT)
	var da := DirAccess.open("res://")
	var root_no_res: String = Contract.PATH_FIXTURE_ROOT.trim_prefix("res://")
	if not da.dir_exists(root_no_res):
		da.make_dir_recursive(root_no_res)

	for layer in Contract.REQUIRED_LAYERS:
		var layer_dir := "%s/%s" % [root_no_res, layer]
		if not da.dir_exists(layer_dir):
			da.make_dir_recursive(layer_dir)

		for state_name in STATES.keys():
			var state_dir := "%s/%s" % [layer_dir, state_name]
			if not da.dir_exists(state_dir):
				da.make_dir_recursive(state_dir)

			var info: Dictionary = STATES[state_name]
			var count: int = info["count"]
			var base_col: Color = info["base_color"]

			for frame_idx in range(count):
				var img := Image.create(Contract.CANVAS_WIDTH, Contract.CANVAS_HEIGHT, false, Image.FORMAT_RGBA8)
				if layer == Contract.LAYER_BASE:
					_draw_base_frame(img, state_name, frame_idx, count, base_col)
				else:
					_draw_scarf_frame(img, state_name, frame_idx, count)

				var filename := Contract.format_frame_filename(state_name, frame_idx)
				var file_path := "res://%s/%s" % [state_dir, filename]
				var err := img.save_png(file_path)
				if err != OK:
					push_error("Failed to save %s: error %d" % [file_path, err])

	print("Finished generating all test fixtures.")
	quit(0)

func _get_pose_parameters(state: String, frame: int, total: int) -> Dictionary:
	var cx: int = Contract.GROUND_ANCHOR.x
	var cy: int = 140
	var rx: int = 40
	var ry: int = 65

	match state:
		"idle":
			cy = int(140.0 + sin(float(frame) / float(total) * TAU) * 4.0)
		"move":
			cx = int(128.0 + sin(float(frame) / float(total) * TAU) * 8.0)
			cy = int(140.0 + absf(cos(float(frame) / float(total) * TAU)) * -5.0)
		"dash":
			cx = int(135.0 + frame * 3)
			cy = 155
			rx = 60
			ry = 38
		"hit":
			cx = int(118.0 - frame * 3)
			cy = 135
			rx = 45
			ry = 60
		"downed":
			var t: float = float(frame) / float(total - 1)
			cy = int(lerpf(140.0, 195.0, t))
			rx = int(lerpf(40.0, 75.0, t))
			ry = int(lerpf(65.0, 18.0, t))
		"revive":
			var t: float = float(frame) / float(total - 1)
			cy = int(lerpf(195.0, 140.0, t))
			rx = int(lerpf(75.0, 40.0, t))
			ry = int(lerpf(18.0, 65.0, t))

	return {"cx": cx, "cy": cy, "rx": rx, "ry": ry}

func _draw_base_frame(img: Image, state: String, frame: int, total: int, color: Color) -> void:
	img.fill(Color(0, 0, 0, 0))

	# Stable ground reference line at ground anchor Y
	var gy: int = Contract.GROUND_ANCHOR.y
	for x in range(32, 224):
		img.set_pixel(x, gy, Color(0.3, 0.4, 0.5, 0.4))
		img.set_pixel(x, gy + 1, Color(0.3, 0.4, 0.5, 0.2))

	# Ground anchor crosshair at (128, 216)
	var gx: int = Contract.GROUND_ANCHOR.x
	for y in range(gy - 4, gy + 5):
		img.set_pixel(gx, y, Color(1, 1, 1, 0.7))
	for x in range(gx - 4, gx + 5):
		img.set_pixel(x, gy, Color(1, 1, 1, 0.7))

	var pose := _get_pose_parameters(state, frame, total)
	var cx: int = pose["cx"]
	var cy: int = pose["cy"]
	var rx: int = pose["rx"]
	var ry: int = pose["ry"]

	# Draw main penguin body mass (excluding scarf)
	for y in range(cy - ry, cy + ry):
		for x in range(cx - rx, cx + rx):
			if x < 0 or x >= Contract.CANVAS_WIDTH or y < 0 or y >= Contract.CANVAS_HEIGHT:
				continue
			var dx: float = float(x - cx) / float(rx)
			var dy: float = float(y - cy) / float(ry)
			if (dx * dx + dy * dy) <= 1.0:
				var shade: float = 1.0 - (dy * 0.2 + dx * 0.1)
				img.set_pixel(x, y, Color(color.r * shade, color.g * shade, color.b * shade, color.a))

	# White belly oval
	var bx: int = cx + int(rx * 0.1)
	var by: int = cy + int(ry * 0.15)
	var brx: int = int(rx * 0.55)
	var bry: int = int(ry * 0.65)
	for y in range(by - bry, by + bry):
		for x in range(bx - brx, bx + brx):
			if x < 0 or x >= Contract.CANVAS_WIDTH or y < 0 or y >= Contract.CANVAS_HEIGHT:
				continue
			var dx: float = float(x - bx) / float(brx)
			var dy: float = float(y - by) / float(bry)
			if (dx * dx + dy * dy) <= 1.0:
				img.set_pixel(x, y, Color(0.92, 0.94, 0.96, 0.95))

	# Body outline
	for y in range(cy - ry - 1, cy + ry + 2):
		for x in range(cx - rx - 1, cx + rx + 2):
			if x < 0 or x >= Contract.CANVAS_WIDTH or y < 0 or y >= Contract.CANVAS_HEIGHT:
				continue
			var dx: float = float(x - cx) / float(rx)
			var dy: float = float(y - cy) / float(ry)
			var dist: float = dx * dx + dy * dy
			if dist > 0.92 and dist <= 1.08:
				img.set_pixel(x, y, Color(0.04, 0.06, 0.09, 0.95))

	# Beak indicator
	var beak_x: int = cx + int(rx * 0.7)
	var beak_y: int = cy - int(ry * 0.3)
	for y in range(beak_y - 3, beak_y + 4):
		for x in range(beak_x - 3, beak_x + 8):
			if x >= 0 and x < Contract.CANVAS_WIDTH and y >= 0 and y < Contract.CANVAS_HEIGHT:
				img.set_pixel(x, y, Color(0.98, 0.65, 0.15, 0.95))

	# Frame index indicator dots inside shape
	for dot in range(total):
		var dx: int = cx - (total * 4) + (dot * 8)
		var dy: int = cy + 20
		var dot_col: Color = Color.WHITE if dot == frame else Color(0.2, 0.2, 0.2, 0.6)
		for py in range(dy - 1, dy + 2):
			for px in range(dx - 1, dx + 2):
				if px >= 0 and px < Contract.CANVAS_WIDTH and py >= 0 and py < Contract.CANVAS_HEIGHT:
					img.set_pixel(px, py, dot_col)

func _draw_scarf_frame(img: Image, state: String, frame: int, total: int) -> void:
	# Entire canvas transparent except for neutral/white scarf geometry
	img.fill(Color(0, 0, 0, 0))

	var pose := _get_pose_parameters(state, frame, total)
	var cx: int = pose["cx"]
	var cy: int = pose["cy"]
	var rx: int = pose["rx"]
	var ry: int = pose["ry"]

	# Scarf position aligns directly over the neck area of the base body
	var sx: int = cx
	var sy: int = cy - int(ry * 0.35)
	var s_rx: int = int(rx * 0.75)
	var s_ry: int = 10

	# Neutral white scarf wrap (ready for runtime modulate)
	for y in range(sy - s_ry, sy + s_ry):
		for x in range(sx - s_rx, sx + s_rx):
			if x < 0 or x >= Contract.CANVAS_WIDTH or y < 0 or y >= Contract.CANVAS_HEIGHT:
				continue
			var dx: float = float(x - sx) / float(s_rx)
			var dy: float = float(y - sy) / float(s_ry)
			if (dx * dx + dy * dy) <= 1.0:
				var shade: float = 1.0 - (dy * 0.15 + dx * 0.1)
				img.set_pixel(x, y, Color(0.95 * shade, 0.95 * shade, 0.95 * shade, 0.98))

	# Scarf tail trailing down
	var tail_x: int = sx - int(s_rx * 0.5)
	var tail_y: int = sy + 6
	for y in range(tail_y, tail_y + 18):
		for x in range(tail_x - 4, tail_x + 6):
			if x >= 0 and x < Contract.CANVAS_WIDTH and y >= 0 and y < Contract.CANVAS_HEIGHT:
				img.set_pixel(x, y, Color(0.90, 0.90, 0.90, 0.98))

	# Subtle outline so it reads against light surfaces
	for y in range(sy - s_ry - 1, sy + s_ry + 2):
		for x in range(sx - s_rx - 1, sx + s_rx + 2):
			if x < 0 or x >= Contract.CANVAS_WIDTH or y < 0 or y >= Contract.CANVAS_HEIGHT:
				continue
			var dx: float = float(x - sx) / float(s_rx)
			var dy: float = float(y - sy) / float(s_ry)
			var dist: float = dx * dx + dy * dy
			if dist > 0.90 and dist <= 1.15:
				img.set_pixel(x, y, Color(0.2, 0.2, 0.2, 0.7))
