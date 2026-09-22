extends SceneTree
## Regenerates the placeholder Frozen Coast terrain textures. Every fill tiles in
## both directions and every edge tiles horizontally, because SmartShape repeats
## fills across the whole shape and lays edge strips end to end.
##
##   godot --headless --path . --script res://experiments/smartshape_frozen_coast/generate_textures.gd
##
## Placeholder art for an evaluation spike: the point is to judge the authoring
## tool, not to ship these.

const OUT := "res://experiments/smartshape_frozen_coast/terrain/"

func _initialize() -> void:
	_fill("snow_fill.png", 256, Color("eaf5fa"), Color("c6dfeb"), 0.010, 0.55, 7)
	_fill("ocean_fill.png", 256, Color("0e2c43"), Color("1a4a66"), 0.014, 0.8, 11)
	_ice("ice_fill.png", 128)
	_cliff("cliff_edge.png", 256, 96)
	_lip("snow_lip_edge.png", 256, 40)
	# Tapers finish an edge run where the material changes or an open shape
	# ends. Without them SmartShape cuts the strip off square.
	_taper("cliff_edge.png", "cliff_taper_left.png", "cliff_taper_right.png")
	_taper("snow_lip_edge.png", "lip_taper_left.png", "lip_taper_right.png")
	print("TEXTURES WRITTEN")
	quit(0)

func _noise(seed_value: int, frequency: float, kind: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_SIMPLEX_SMOOTH) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = frequency
	noise.noise_type = kind
	return noise

## A value that repeats exactly every `width` pixels, for edges that tile in x.
func _periodic(x: float, width: float, seed_value: int) -> float:
	var total := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for harmonic: int in [1, 2, 3, 5, 8]:
		total += sin(TAU * harmonic * x / width + rng.randf() * TAU) / float(harmonic)
	return total * 0.5

func _fill(file: String, size: int, base: Color, shade: Color, frequency: float, strength: float, seed_value: int) -> void:
	var broad: Image = _noise(seed_value, frequency).get_seamless_image(size, size)
	var grain: Image = _noise(seed_value + 1, 0.09).get_seamless_image(size, size)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for y: int in range(size):
		for x: int in range(size):
			var blotch: float = broad.get_pixel(x, y).r
			var fine: float = grain.get_pixel(x, y).r - 0.5
			var color: Color = base.lerp(shade, clampf(blotch * strength, 0.0, 1.0))
			image.set_pixel(x, y, color.lightened(fine * 0.06))
	# Sparkle only suits the snow; the ocean gets faint wave glints instead.
	for index: int in range(size / 2):
		var at := Vector2i(rng.randi_range(0, size - 1), rng.randi_range(0, size - 1))
		image.set_pixel(at.x, at.y, image.get_pixel(at.x, at.y).lerp(Color.WHITE, 0.55))
	image.save_png(OUT + file)

func _ice(file: String, size: int) -> void:
	var cells := _noise(21, 0.045, FastNoiseLite.TYPE_CELLULAR)
	cells.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	var cracks: Image = cells.get_seamless_image(size, size)
	var body: Image = _noise(22, 0.02).get_seamless_image(size, size)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y: int in range(size):
		for x: int in range(size):
			var color: Color = Color("d3eff8").lerp(Color("a6d6e8"), body.get_pixel(x, y).r * 0.7)
			if cracks.get_pixel(x, y).r < 0.06:
				color = color.lerp(Color("7fb3cb"), 0.75)
			image.set_pixel(x, y, color)
	image.save_png(OUT + file)

## The camera-facing cliff: a snow cap at the top that matches the snow fill, a
## striated ice face, and a dark waterline that fades into the ocean.
func _cliff(file: String, width: int, height: int) -> void:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for x: int in range(width):
		var cap: float = 16.0 + _periodic(x, width, 3) * 7.0
		var streak: float = _periodic(x, width, 4) * 0.5 + _periodic(x * 3.0, width, 5) * 0.25
		for y: int in range(height):
			var color: Color
			if y < cap:
				color = Color("eaf5fa").lerp(Color("d9ebf3"), float(y) / cap)
			elif y < cap + 3.0:
				color = Color("f7fcff")
			else:
				var depth: float = (y - cap) / (height - cap)
				color = Color("a4d0e2").lerp(Color("2f6480"), depth)
				color = color.lightened(streak * 0.12)
				if y > height - 14:
					var wet: float = (y - (height - 14)) / 14.0
					color = color.lerp(Color("0e2c43"), wet)
					color.a = 1.0 - wet * 0.85
			image.set_pixel(x, y, color)
	# SmartShape lays an edge strip with its top towards the outward normal, which
	# for a camera-facing cliff is the water. Flip so the snow cap meets the land.
	image.flip_y()
	image.save_png(OUT + file)

## A soft snow rim for edges that face away from the camera: bright lip, a pale
## ice fringe on the water side, fading into the snow fill on the land side.
func _lip(file: String, width: int, height: int) -> void:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for x: int in range(width):
		var fringe: float = 8.0 + _periodic(x, width, 9) * 5.0
		for y: int in range(height):
			var color: Color
			if y < fringe:
				color = Color("bfe5f2")
				color.a = clampf((y - fringe + 6.0) / 6.0, 0.0, 0.9)
			elif y < fringe + 2.5:
				color = Color("5d8ea8")
			elif y < fringe + 12.0:
				color = Color("ffffff").lerp(Color("e3f1f7"), (y - fringe) / 12.0)
			else:
				color = Color("eaf5fa")
				color.a = clampf(1.0 - (y - fringe - 12.0) / (height - fringe - 12.0), 0.0, 1.0)
			image.set_pixel(x, y, color)
	image.save_png(OUT + file)

## Cuts a short piece off an edge texture and fades it out towards one end.
func _taper(source: String, left_file: String, right_file: String) -> void:
	var edge := Image.load_from_file(OUT + source)
	var width: int = 64
	var height: int = edge.get_height()
	for right: bool in [false, true]:
		var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
		for x: int in range(width):
			# 0 at the tip, 1 where it meets the full strip.
			var ramp: float = float(x) / float(width - 1) if not right else 1.0 - float(x) / float(width - 1)
			var reach: float = height * (0.35 + 0.65 * ramp)
			for y: int in range(height):
				var color: Color = edge.get_pixel(x, y)
				if y > reach:
					color.a = 0.0
				color.a *= smoothstep(0.0, 0.5, ramp)
				image.set_pixel(x, y, color)
		image.save_png(OUT + (right_file if right else left_file))
