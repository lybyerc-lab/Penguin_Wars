class_name CharacterAnimationValidator
extends RefCounted
## Production Animation Import Validator for Penguin Wars.
## Validates two-layer asset directory structure (base and scarf), PNG frame naming conventions,
## canvas dimensions, frame synchronization, transparency, SpriteFrames configurations,
## and CharacterPresentationProfile bindings.

const Contract = preload("res://scripts/data/character_animation_contract.gd")

## Validates a two-layer animation asset folder on disk (alias for validate_directory_layout).
static func validate_directory(dir_path: String, expected_canvas: Vector2i = Contract.CANVAS_SIZE) -> Array[String]:
	return validate_directory_layout(dir_path, expected_canvas)

## Validates a two-layer animation asset folder on disk (e.g. res://tests/fixtures/character_animation).
static func validate_directory_layout(dir_path: String, expected_canvas: Vector2i = Contract.CANVAS_SIZE) -> Array[String]:
	var errors: Array[String] = []
	var da := DirAccess.open(dir_path)
	if da == null:
		errors.append("Asset directory does not exist: %s" % dir_path)
		return errors

	# Check that runtime folder is not inside art/blender
	if "art/blender" in dir_path or "art\\blender" in dir_path:
		errors.append("Invalid runtime asset path: runtime frames must not reside in source art folder 'art/blender': %s" % dir_path)

	# Verify required layers exist: base and scarf
	for layer in Contract.REQUIRED_LAYERS:
		var layer_path := "%s/%s" % [dir_path, layer]
		if not da.dir_exists(layer):
			errors.append("Missing required animation layer directory: %s" % layer_path)

	if not errors.is_empty():
		return errors

	# For each canonical state, validate both base and scarf layers
	for state_name in Contract.CANONICAL_STATES:
		var base_path := "%s/%s/%s" % [dir_path, Contract.LAYER_BASE, state_name]
		var scarf_path := "%s/%s/%s" % [dir_path, Contract.LAYER_SCARF, state_name]

		var base_files := _get_state_pngs(base_path, state_name, Contract.LAYER_BASE, errors)
		var scarf_files := _get_state_pngs(scarf_path, state_name, Contract.LAYER_SCARF, errors)

		# Check both have frames
		if base_files.is_empty():
			errors.append("Base layer state '%s' has no animation frames in: %s" % [state_name, base_path])
		if scarf_files.is_empty():
			errors.append("Scarf layer state '%s' has no animation frames in: %s" % [state_name, scarf_path])

		if base_files.is_empty() or scarf_files.is_empty():
			continue

		# Verify exact same frame count between base and scarf
		if base_files.size() != scarf_files.size():
			errors.append("Layer frame count mismatch in state '%s': base has %d frames, scarf has %d frames" % [
				state_name, base_files.size(), scarf_files.size()
			])

		# Validate naming and sequential indices for base
		_validate_frame_sequence(base_files, state_name, Contract.LAYER_BASE, errors)
		# Validate naming and sequential indices for scarf
		_validate_frame_sequence(scarf_files, state_name, Contract.LAYER_SCARF, errors)

		# Validate counterpart frame matching: every base frame must have exact counterpart in scarf
		for i in range(mini(base_files.size(), scarf_files.size())):
			if base_files[i] != scarf_files[i]:
				errors.append("Counterpart frame mismatch in state '%s' index %d: base '%s' vs scarf '%s'" % [
					state_name, i, base_files[i], scarf_files[i]
				])

		# Validate image dimensions and format
		_validate_images(base_path, base_files, state_name, Contract.LAYER_BASE, expected_canvas, false, errors)
		_validate_images(scarf_path, scarf_files, state_name, Contract.LAYER_SCARF, expected_canvas, true, errors)

	return errors

static func _get_state_pngs(dir_path: String, state_name: String, layer_name: String, errors: Array[String]) -> Array[String]:
	var da := DirAccess.open(dir_path)
	if da == null:
		errors.append("Cannot open state directory: %s" % dir_path)
		return []

	da.list_dir_begin()
	var fname := da.get_next()
	var pngs: Array[String] = []

	while fname != "":
		if not da.current_is_dir():
			if fname.ends_with(".png"):
				pngs.append(fname)
			elif fname != ".gitkeep" and not fname.ends_with(".import"):
				errors.append("Unexpected non-PNG file in %s/%s: %s" % [layer_name, state_name, fname])
		fname = da.get_next()
	da.list_dir_end()

	pngs.sort()
	return pngs

static func _validate_frame_sequence(png_files: Array[String], state_name: String, layer_name: String, errors: Array[String]) -> void:
	var expected_prefix := "%s_%s_" % [Contract.FILE_PREFIX, state_name]
	var frame_indices: Array[int] = []

	for fname in png_files:
		if not fname.begins_with(expected_prefix) or not fname.ends_with(".png"):
			errors.append("[%s] File '%s' does not match naming convention 'penguin_%s_###.png'" % [
				layer_name, fname, state_name
			])
			continue

		var num_str := fname.substr(expected_prefix.length(), fname.length() - expected_prefix.length() - 4)
		if num_str.length() != 3 or not num_str.is_valid_int():
			errors.append("[%s] File '%s' must have 3-digit zero-padded index (e.g. 000, 001)" % [
				layer_name, fname
			])
			continue

		var idx := num_str.to_int()
		if frame_indices.has(idx):
			errors.append("[%s] Duplicate frame index %03d in state '%s': %s" % [layer_name, idx, state_name, fname])
		else:
			frame_indices.append(idx)

	frame_indices.sort()
	for i in range(frame_indices.size()):
		if frame_indices[i] != i:
			errors.append("[%s] Non-sequential frame numbering in state '%s': expected index %03d, got %03d" % [
				layer_name, state_name, i, frame_indices[i]
			])
			break

static func _validate_images(dir_path: String, png_files: Array[String], state_name: String, layer_name: String, expected_canvas: Vector2i, require_transparency: bool, errors: Array[String]) -> void:
	var first_dim := Vector2i.ZERO
	for fname in png_files:
		var full_path := "%s/%s" % [dir_path, fname]
		var img := Image.load_from_file(ProjectSettings.globalize_path(full_path))
		if img == null or img.is_empty():
			errors.append("[%s] Corrupt or unreadable PNG frame: %s" % [layer_name, full_path])
			continue

		var dim := Vector2i(img.get_width(), img.get_height())
		if first_dim == Vector2i.ZERO:
			first_dim = dim
			if expected_canvas != Vector2i.ZERO and dim != expected_canvas:
				errors.append("[%s] State '%s' frame dimensions %dx%d do not match expected canvas %dx%d (%s)" % [
					layer_name, state_name, dim.x, dim.y, expected_canvas.x, expected_canvas.y, fname
				])
		elif dim != first_dim:
			errors.append("[%s] Inconsistent frame dimensions in state '%s': '%s' is %dx%d, expected %dx%d" % [
				layer_name, state_name, fname, dim.x, dim.y, first_dim.x, first_dim.y
			])

		if require_transparency:
			# Verify scarf overlay has transparency (not a solid opaque square)
			var has_transparent_pixels: bool = false
			# Sample corner pixels which must be transparent
			for sample_pos in [Vector2i(0, 0), Vector2i(dim.x - 1, 0), Vector2i(0, dim.y - 1), Vector2i(dim.x - 1, dim.y - 1)]:
				if img.get_pixelv(sample_pos).a < 0.1:
					has_transparent_pixels = true
					break
			if not has_transparent_pixels:
				errors.append("[%s] Scarf frame '%s' lacks transparent background" % [layer_name, fname])

## Validates a compiled SpriteFrames resource against the contract.
static func validate_sprite_frames(frames: SpriteFrames, expected_canvas: Vector2i = Contract.CANVAS_SIZE, expected_fps: float = Contract.SOURCE_FPS) -> Array[String]:
	var errors: Array[String] = []
	if frames == null:
		errors.append("SpriteFrames resource is null")
		return errors

	for state_name in Contract.CANONICAL_STATES:
		if not frames.has_animation(state_name):
			errors.append("SpriteFrames missing canonical animation: '%s'" % state_name)
			continue

		var frame_count := frames.get_frame_count(state_name)
		if frame_count <= 0:
			errors.append("SpriteFrames animation '%s' has 0 frames" % state_name)
			continue

		var speed := frames.get_animation_speed(state_name)
		if not is_equal_approx(speed, expected_fps):
			errors.append("Wrong FPS for animation '%s': expected %.1f, got %.1f" % [state_name, expected_fps, speed])

		var loop_flag := frames.get_animation_loop(state_name)
		var expected_loop: bool = Contract.is_state_looping(state_name)
		if loop_flag != expected_loop:
			errors.append("Wrong loop flag for animation '%s': expected %s, got %s" % [state_name, expected_loop, loop_flag])

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
static func validate_profile(profile: Resource, expected_canvas: Vector2i = Contract.CANVAS_SIZE) -> Array[String]:
	var errors: Array[String] = []
	if profile == null:
		errors.append("Profile resource is null")
		return errors

	if not "sprite_frames" in profile or profile.sprite_frames == null:
		errors.append("Profile does not contain valid base sprite_frames")
		return errors

	var base_errors := validate_sprite_frames(profile.sprite_frames, expected_canvas)
	errors.append_array(base_errors)

	if "scarf_sprite_frames" in profile and profile.scarf_sprite_frames != null:
		var scarf_errors := validate_sprite_frames(profile.scarf_sprite_frames, expected_canvas)
		errors.append_array(scarf_errors)
	else:
		errors.append("Profile does not contain valid scarf_sprite_frames")

	# Verify animation mapping properties exist
	for state_name in Contract.CANONICAL_STATES:
		var prop_name := "anim_%s" % state_name
		if not prop_name in profile:
			errors.append("Profile missing state animation property '%s'" % prop_name)
		else:
			var mapped_anim: StringName = profile.get(prop_name)
			if not profile.sprite_frames.has_animation(mapped_anim):
				errors.append("Profile property '%s' maps to non-existent animation '%s'" % [prop_name, mapped_anim])

	# Verify scale and offset
	if "base_scale" in profile and profile.base_scale != Contract.RUNTIME_SCALE:
		errors.append("Profile base_scale %s does not match contract %s" % [profile.base_scale, Contract.RUNTIME_SCALE])
	if "offset" in profile and profile.offset != Contract.RUNTIME_OFFSET:
		errors.append("Profile offset %s does not match contract %s" % [profile.offset, Contract.RUNTIME_OFFSET])

	return errors
