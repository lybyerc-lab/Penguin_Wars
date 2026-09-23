class_name CharacterAnimationValidator
extends RefCounted
## Production Animation Import Validator for Penguin Wars.
## Validates asset directory structure, PNG frame naming conventions, canvas dimensions,
## frame sequencing, SpriteFrames configurations, and CharacterPresentationProfile bindings.

const CANONICAL_STATES: Array[String] = [
	"idle",
	"move",
	"dash",
	"hit",
	"downed",
	"revive",
]

const EXPECTED_LOOP_FLAGS: Dictionary = {
	"idle": true,
	"move": true,
	"dash": false,
	"hit": false,
	"downed": false,
	"revive": false,
}

const EXPECTED_FPS: float = 24.0
const DEFAULT_CANVAS_SIZE: Vector2i = Vector2i(256, 256)

## Validates a production asset folder on disk (e.g. res://assets/characters/penguin/production).
static func validate_directory(dir_path: String, expected_canvas: Vector2i = DEFAULT_CANVAS_SIZE) -> Array[String]:
	var errors: Array[String] = []
	var da := DirAccess.open(dir_path)
	if da == null:
		errors.append("Production asset directory does not exist: %s" % dir_path)
		return errors

	# Check that runtime folder is not inside art/blender
	if "art/blender" in dir_path or "art\\blender" in dir_path:
		errors.append("Invalid runtime asset path: runtime frames must not reside in source art folder 'art/blender': %s" % dir_path)

	# Check each canonical state subdirectory
	for state_name in CANONICAL_STATES:
		var state_path := "%s/%s" % [dir_path, state_name]
		if not da.dir_exists(state_name):
			errors.append("Missing canonical state directory: %s" % state_path)
			continue

		var state_da := DirAccess.open(state_path)
		if state_da == null:
			errors.append("Cannot open state directory: %s" % state_path)
			continue

		state_da.list_dir_begin()
		var file_name := state_da.get_next()
		var png_files: Array[String] = []

		while file_name != "":
			if not state_da.current_is_dir():
				if file_name.ends_with(".png"):
					png_files.append(file_name)
				elif not file_name.ends_with(".import"):
					errors.append("Unexpected non-PNG file in state '%s': %s" % [state_name, file_name])
			file_name = state_da.get_next()
		state_da.list_dir_end()

		if png_files.is_empty():
			errors.append("State '%s' has no animation frames in: %s" % [state_name, state_path])
			continue

		# Validate naming convention: penguin_<state>_<###>.png
		var expected_prefix := "penguin_%s_" % state_name
		var frame_indices: Array[int] = []

		for fname in png_files:
			if not fname.begins_with(expected_prefix) or not fname.ends_with(".png"):
				errors.append("File '%s' in state '%s' does not match naming convention 'penguin_%s_###.png'" % [
					fname, state_name, state_name
				])
				continue

			var num_str := fname.substr(expected_prefix.length(), fname.length() - expected_prefix.length() - 4)
			if num_str.length() != 3 or not num_str.is_valid_int():
				errors.append("File '%s' in state '%s' must have 3-digit zero-padded index (e.g. 000, 001)" % [
					fname, state_name
				])
				continue

			var idx := num_str.to_int()
			if frame_indices.has(idx):
				errors.append("Duplicate frame index %03d in state '%s': %s" % [idx, state_name, fname])
			else:
				frame_indices.append(idx)

		# Validate sequential numbering from 0
		frame_indices.sort()
		for i in range(frame_indices.size()):
			if frame_indices[i] != i:
				errors.append("Non-sequential frame numbering in state '%s': expected index %03d, got %03d" % [
					state_name, i, frame_indices[i]
				])
				break

		# Validate image dimensions
		var first_dim := Vector2i.ZERO
		for fname in png_files:
			var full_path := "%s/%s" % [state_path, fname]
			var img := Image.load_from_file(ProjectSettings.globalize_path(full_path))
			if img == null or img.is_empty():
				errors.append("Corrupt or unreadable PNG frame: %s" % full_path)
				continue

			var dim := Vector2i(img.get_width(), img.get_height())
			if first_dim == Vector2i.ZERO:
				first_dim = dim
				if expected_canvas != Vector2i.ZERO and dim != expected_canvas:
					errors.append("State '%s' frame dimensions %dx%d do not match expected canvas %dx%d (%s)" % [
						state_name, dim.x, dim.y, expected_canvas.x, expected_canvas.y, fname
					])
			elif dim != first_dim:
				errors.append("Inconsistent frame dimensions in state '%s': '%s' is %dx%d, expected %dx%d" % [
					state_name, fname, dim.x, dim.y, first_dim.x, first_dim.y
				])

	return errors

## Validates a compiled SpriteFrames resource against the production contract.
static func validate_sprite_frames(frames: SpriteFrames, expected_canvas: Vector2i = DEFAULT_CANVAS_SIZE) -> Array[String]:
	var errors: Array[String] = []
	if frames == null:
		errors.append("SpriteFrames resource is null")
		return errors

	for state_name in CANONICAL_STATES:
		if not frames.has_animation(state_name):
			errors.append("SpriteFrames missing canonical animation: '%s'" % state_name)
			continue

		var frame_count := frames.get_frame_count(state_name)
		if frame_count <= 0:
			errors.append("SpriteFrames animation '%s' has 0 frames" % state_name)
			continue

		var speed := frames.get_animation_speed(state_name)
		if not is_equal_approx(speed, EXPECTED_FPS):
			errors.append("Wrong FPS for animation '%s': expected %.1f, got %.1f" % [state_name, EXPECTED_FPS, speed])

		var loop_flag := frames.get_animation_loop(state_name)
		var expected_loop: bool = EXPECTED_LOOP_FLAGS.get(state_name, false)
		if loop_flag != expected_loop:
			errors.append("Wrong loop flag for animation '%s': expected %s, got %s" % [state_name, expected_loop, loop_flag])

		# Validate texture dimensions if loaded
		for i in range(frame_count):
			var tex := frames.get_frame_texture(state_name, i)
			if tex == null:
				errors.append("Animation '%s' frame %d texture is null" % [state_name, i])
			elif expected_canvas != Vector2i.ZERO:
				var size := tex.get_size()
				if int(size.x) != expected_canvas.x or int(size.y) != expected_canvas.y:
					errors.append("Animation '%s' frame %d dimension %dx%d does not match expected %dx%d" % [
						state_name, i, int(size.x), int(size.y), expected_canvas.x, expected_canvas.y
					])

	return errors

## Validates that a CharacterPresentationProfile resource correctly binds the production contract.
static func validate_profile(profile: Resource, expected_canvas: Vector2i = DEFAULT_CANVAS_SIZE) -> Array[String]:
	var errors: Array[String] = []
	if profile == null:
		errors.append("Profile resource is null")
		return errors

	if not "sprite_frames" in profile or profile.sprite_frames == null:
		errors.append("Profile does not contain valid sprite_frames")
		return errors

	var frames_errors := validate_sprite_frames(profile.sprite_frames, expected_canvas)
	errors.append_array(frames_errors)

	# Verify animation mapping properties exist
	for state_name in CANONICAL_STATES:
		var prop_name := "anim_%s" % state_name
		if not prop_name in profile:
			errors.append("Profile missing state animation property '%s'" % prop_name)
		else:
			var mapped_anim: StringName = profile.get(prop_name)
			if not profile.sprite_frames.has_animation(mapped_anim):
				errors.append("Profile property '%s' maps to non-existent animation '%s'" % [prop_name, mapped_anim])

	return errors
