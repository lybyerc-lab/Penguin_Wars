extends SceneTree
## Builder script to compile two-layer animation frames (base and scarf) into
## SpriteFrames and CharacterPresentationProfile resources.
## Supports arbitrary sequential frame counts per animation.
## Can target either production (assets/characters/penguin/production)
## or fixture (tests/fixtures/character_animation).

const Contract = preload("res://scripts/data/character_animation_contract.gd")
const ProfileScript = preload("res://scripts/data/character_presentation_profile.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var is_fixture: bool = false
	var custom_root: String = ""

	for arg in args:
		if arg == "--fixture":
			is_fixture = true
		elif arg.begins_with("--root="):
			custom_root = arg.trim_prefix("--root=")

	var root_dir: String = custom_root
	if root_dir.is_empty():
		root_dir = Contract.PATH_FIXTURE_ROOT if is_fixture else Contract.PATH_PRODUCTION_ROOT

	var profile_path: String = Contract.PATH_FIXTURE_PROFILE if is_fixture else Contract.PATH_PRODUCTION_PROFILE
	var base_frames_path: String = Contract.PATH_FIXTURE_SPRITE_FRAMES if is_fixture else Contract.PATH_PRODUCTION_SPRITE_FRAMES
	var scarf_frames_path: String = Contract.PATH_FIXTURE_SCARF_FRAMES if is_fixture else Contract.PATH_PRODUCTION_SCARF_FRAMES
	var prof_name: String = "Penguin Fixture Profile" if is_fixture else "Penguin Production Rig v2"

	# If default production root has no frames yet (e.g. before Claude renders), build fixture profile by default
	var da := DirAccess.open(root_dir)
	var has_content: bool = false
	if da != null and da.dir_exists(Contract.LAYER_BASE):
		var base_da := DirAccess.open("%s/%s" % [root_dir, Contract.LAYER_BASE])
		if base_da != null and base_da.dir_exists("idle"):
			var idle_da := DirAccess.open("%s/%s/idle" % [root_dir, Contract.LAYER_BASE])
			if idle_da != null:
				idle_da.list_dir_begin()
				var fn := idle_da.get_next()
				while fn != "":
					if fn.ends_with(".png"):
						has_content = true
						break
					fn = idle_da.get_next()
				idle_da.list_dir_end()

	if not has_content and not is_fixture and custom_root.is_empty():
		print("Production folder %s contains no frames yet. Building fixture profile instead..." % root_dir)
		root_dir = Contract.PATH_FIXTURE_ROOT
		profile_path = Contract.PATH_FIXTURE_PROFILE
		base_frames_path = Contract.PATH_FIXTURE_SPRITE_FRAMES
		scarf_frames_path = Contract.PATH_FIXTURE_SCARF_FRAMES
		prof_name = "Penguin Fixture Profile"

	var err := build_from_root(root_dir, profile_path, base_frames_path, scarf_frames_path, prof_name)
	if err != OK:
		push_error("Build failed with error %d" % err)
		quit(1)
	else:
		print("Build completed successfully.")
		quit(0)

static func build_from_root(
	root_path: String,
	output_profile_path: String,
	output_base_frames_path: String,
	output_scarf_frames_path: String,
	profile_name: String = "Penguin Presentation Profile"
) -> Error:
	print("Building two-layer presentation resources from: %s" % root_path)

	var base_frames := _build_layer_sprite_frames(root_path, Contract.LAYER_BASE)
	if base_frames == null:
		return ERR_FILE_NOT_FOUND

	var scarf_frames := _build_layer_sprite_frames(root_path, Contract.LAYER_SCARF)
	if scarf_frames == null:
		return ERR_FILE_NOT_FOUND

	var err_bf := ResourceSaver.save(base_frames, output_base_frames_path)
	if err_bf != OK:
		push_error("Failed to save base SpriteFrames to %s: error %d" % [output_base_frames_path, err_bf])
		return err_bf
	print("Saved base SpriteFrames: %s" % output_base_frames_path)

	var err_sf := ResourceSaver.save(scarf_frames, output_scarf_frames_path)
	if err_sf != OK:
		push_error("Failed to save scarf SpriteFrames to %s: error %d" % [output_scarf_frames_path, err_sf])
		return err_sf
	print("Saved scarf SpriteFrames: %s" % output_scarf_frames_path)

	var profile := ProfileScript.new()
	profile.profile_name = profile_name
	profile.sprite_frames = base_frames
	profile.scarf_sprite_frames = scarf_frames
	profile.base_scale = Contract.RUNTIME_SCALE
	profile.offset = Contract.RUNTIME_OFFSET
	profile.flip_h_with_facing = true
	profile.anim_idle = &"idle"
	profile.anim_move = &"move"
	profile.anim_dash = &"dash"
	profile.anim_hit = &"hit"
	profile.anim_downed = &"downed"
	profile.anim_revive = &"revive"

	var err_prof := ResourceSaver.save(profile, output_profile_path)
	if err_prof != OK:
		push_error("Failed to save Profile to %s: error %d" % [output_profile_path, err_prof])
		return err_prof
	print("Saved CharacterPresentationProfile: %s" % output_profile_path)

	return OK

static func _build_layer_sprite_frames(root_path: String, layer_name: String) -> SpriteFrames:
	var layer_path := "%s/%s" % [root_path, layer_name]
	var da := DirAccess.open(layer_path)
	if da == null:
		push_error("Missing layer directory: %s" % layer_path)
		return null

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	for state_name in Contract.CANONICAL_STATES:
		var state_path := "%s/%s" % [layer_path, state_name]
		if not da.dir_exists(state_name):
			push_error("Missing state directory: %s" % state_path)
			return null

		frames.add_animation(state_name)
		frames.set_animation_speed(state_name, Contract.SOURCE_FPS)
		frames.set_animation_loop(state_name, Contract.is_state_looping(state_name))

		var state_da := DirAccess.open(state_path)
		var files: Array[String] = []
		if state_da != null:
			state_da.list_dir_begin()
			var fn := state_da.get_next()
			while fn != "":
				if not state_da.current_is_dir() and fn.ends_with(".png"):
					files.append(fn)
				fn = state_da.get_next()
			state_da.list_dir_end()

		files.sort()
		if files.is_empty():
			push_error("No PNG frames in %s" % state_path)
			return null

		for f in files:
			var tex_path := "%s/%s" % [state_path, f]
			var tex: Texture2D = null
			if ResourceLoader.exists(tex_path):
				tex = load(tex_path)
			if tex == null:
				var img := Image.load_from_file(ProjectSettings.globalize_path(tex_path))
				if img != null and not img.is_empty():
					tex = ImageTexture.create_from_image(img)
			if tex != null:
				frames.add_frame(state_name, tex)
			else:
				push_error("Failed to load frame texture: %s" % tex_path)

		print("[%s] State '%s': discovered %d frames, loop=%s, speed=%.1f fps" % [
			layer_name, state_name, frames.get_frame_count(state_name),
			frames.get_animation_loop(state_name), frames.get_animation_speed(state_name)
		])

	return frames
