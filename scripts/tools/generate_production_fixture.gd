extends SceneTree
## Tool script to generate temporary diagnostic test fixtures for the Penguin Wars
## production character animation import contract.
## Generates uniform 256x256 PNGs in assets/characters/penguin/production/<state>/
## Clearly marked as TEMPORARY TEST FIXTURES.

const BASE_DIR: String = "res://assets/characters/penguin/production"
const CANVAS_WIDTH: int = 256
const CANVAS_HEIGHT: int = 256

const STATES = {
	"idle": {"count": 4, "color": Color(0.22, 0.74, 0.97, 0.85)},
	"move": {"count": 8, "color": Color(0.20, 0.85, 0.65, 0.85)},
	"dash": {"count": 4, "color": Color(0.98, 0.75, 0.18, 0.85)},
	"hit": {"count": 3, "color": Color(0.95, 0.28, 0.35, 0.85)},
	"downed": {"count": 6, "color": Color(0.45, 0.35, 0.65, 0.85)},
	"revive": {"count": 6, "color": Color(0.98, 0.88, 0.45, 0.85)},
}

func _initialize() -> void:
	print("Generating diagnostic animation fixtures...")
	var da := DirAccess.open("res://")
	if not da.dir_exists("assets/characters/penguin/production"):
		da.make_dir_recursive("assets/characters/penguin/production")

	for state_name in STATES.keys():
		var dir_path := "%s/%s" % [BASE_DIR, state_name]
		if not da.dir_exists(dir_path):
			da.make_dir_recursive(dir_path)

		var info: Dictionary = STATES[state_name]
		var count: int = info["count"]
		var color: Color = info["color"]

		for frame_idx in range(count):
			var img := Image.create(CANVAS_WIDTH, CANVAS_HEIGHT, false, Image.FORMAT_RGBA8)
			_draw_fixture_frame(img, state_name, frame_idx, count, color)
			var file_path := "%s/penguin_%s_%03d.png" % [dir_path, state_name, frame_idx]
			var err := img.save_png(file_path)
			if err != OK:
				push_error("Failed to save %s: error %d" % [file_path, err])
			else:
				print("Saved %s" % file_path)

	print("Finished generating fixtures.")
	quit(0)

func _draw_fixture_frame(img: Image, state: String, frame: int, total: int, color: Color) -> void:
	# Transparent background by default
	img.fill(Color(0, 0, 0, 0))

	# Stable ground reference line at y = 216
	for x in range(32, 224):
		img.set_pixel(x, 216, Color(0.3, 0.4, 0.5, 0.4))
		img.set_pixel(x, 217, Color(0.3, 0.4, 0.5, 0.2))

	# Center anchor marker at (128, 216)
	for y in range(212, 221):
		img.set_pixel(128, y, Color(1, 1, 1, 0.7))
	for x in range(124, 133):
		img.set_pixel(x, 216, Color(1, 1, 1, 0.7))

	# Character silhouette block moving slightly by frame
	var cx: int = 128
	var cy: int = 140
	var rx: int = 40
	var ry: int = 65

	match state:
		"idle":
			# Breathing bob
			cy = int(140.0 + sin(float(frame) / float(total) * TAU) * 4.0)
		"move":
			# Waddle sway and step lift
			cx = int(128.0 + sin(float(frame) / float(total) * TAU) * 8.0)
			cy = int(140.0 + absf(cos(float(frame) / float(total) * TAU)) * -5.0)
		"dash":
			# Forward lean (wider, lower)
			cx = int(135.0 + frame * 3)
			cy = 155
			rx = 60
			ry = 38
		"hit":
			# Recoil back
			cx = int(118.0 - frame * 4)
			cy = 135
			rx = 45
			ry = 60
		"downed":
			# Collapsing from upright to flat on ice
			var t: float = float(frame) / float(total - 1)
			cy = int(lerpf(140.0, 195.0, t))
			rx = int(lerpf(40.0, 75.0, t))
			ry = int(lerpf(65.0, 18.0, t))
		"revive":
			# Pushing up from ice to upright
			var t: float = float(frame) / float(total - 1)
			cy = int(lerpf(195.0, 140.0, t))
			rx = int(lerpf(75.0, 40.0, t))
			ry = int(lerpf(18.0, 65.0, t))

	# Draw filled oval for character mass
	for y in range(cy - ry, cy + ry):
		for x in range(cx - rx, cx + rx):
			if x < 0 or x >= CANVAS_WIDTH or y < 0 or y >= CANVAS_HEIGHT:
				continue
			var dx: float = float(x - cx) / float(rx)
			var dy: float = float(y - cy) / float(ry)
			if (dx * dx + dy * dy) <= 1.0:
				# Shaded fill
				var shade: float = 1.0 - (dy * 0.2 + dx * 0.1)
				img.set_pixel(x, y, Color(color.r * shade, color.g * shade, color.b * shade, color.a))

	# Outline
	for y in range(cy - ry - 1, cy + ry + 2):
		for x in range(cx - rx - 1, cx + rx + 2):
			if x < 0 or x >= CANVAS_WIDTH or y < 0 or y >= CANVAS_HEIGHT:
				continue
			var dx: float = float(x - cx) / float(rx)
			var dy: float = float(y - cy) / float(ry)
			var dist: float = dx * dx + dy * dy
			if dist > 0.92 and dist <= 1.08:
				img.set_pixel(x, y, Color(0.05, 0.08, 0.12, 0.9))

	# Frame index indicator dots inside the shape
	for dot in range(total):
		var dx: int = cx - (total * 4) + (dot * 8)
		var dy: int = cy + 10
		var dot_col: Color = Color.WHITE if dot == frame else Color(0.2, 0.2, 0.2, 0.6)
		for py in range(dy - 1, dy + 2):
			for px in range(dx - 1, dx + 2):
				if px >= 0 and px < CANVAS_WIDTH and py >= 0 and py < CANVAS_HEIGHT:
					img.set_pixel(px, py, dot_col)
