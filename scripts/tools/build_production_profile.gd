extends SceneTree
## Builder script to compile assets/characters/penguin/production/ into
## resources/characters/penguin_production_sprite_frames.tres and
## resources/characters/penguin_production_profile.tres.

const ProfileScript = preload("res://scripts/data/character_presentation_profile.gd")
const PROD_ASSET_BASE: String = "res://assets/characters/penguin/production"
const SPRITE_FRAMES_PATH: String = "res://resources/characters/penguin_production_sprite_frames.tres"
const PROFILE_PATH: String = "res://resources/characters/penguin_production_profile.tres"

const STATES = {
	"idle": {"loop": true, "speed": 24.0},
	"move": {"loop": true, "speed": 24.0},
	"dash": {"loop": false, "speed": 24.0},
	"hit": {"loop": false, "speed": 24.0},
	"downed": {"loop": false, "speed": 24.0},
	"revive": {"loop": false, "speed": 24.0},
}

func _initialize() -> void:
	print("Building production SpriteFrames and Profile resources...")
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var da := DirAccess.open("res://")

	for state_name in STATES.keys():
		var dir_path := "%s/%s" % [PROD_ASSET_BASE, state_name]
		if not da.dir_exists(dir_path):
			push_error("Missing state directory: %s" % dir_path)
			continue

		frames.add_animation(state_name)
		frames.set_animation_speed(state_name, STATES[state_name]["speed"])
		frames.set_animation_loop(state_name, STATES[state_name]["loop"])

		var state_da := DirAccess.open(dir_path)
		if state_da != null:
			state_da.list_dir_begin()
			var file_name := state_da.get_next()
			var files: Array[String] = []
			while file_name != "":
				if not state_da.current_is_dir() and file_name.ends_with(".png"):
					files.append(file_name)
				file_name = state_da.get_next()
			state_da.list_dir_end()

			files.sort()
			for f in files:
				var tex_path := "%s/%s" % [dir_path, f]
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
					push_error("Failed to load texture: %s" % tex_path)

		print("Configured animation '%s': %d frames, loop=%s, speed=%.1f fps" % [
			state_name,
			frames.get_frame_count(state_name),
			frames.get_animation_loop(state_name),
			frames.get_animation_speed(state_name)
		])

	var err_frames := ResourceSaver.save(frames, SPRITE_FRAMES_PATH)
	if err_frames != OK:
		push_error("Failed to save %s: %d" % [SPRITE_FRAMES_PATH, err_frames])
	else:
		print("Saved %s" % SPRITE_FRAMES_PATH)

	var profile := ProfileScript.new()
	profile.profile_name = "Penguin Production Rig v2"
	profile.sprite_frames = frames
	profile.base_scale = Vector2(0.25, 0.25)
	# Center anchor: in a 256x256 canvas with ground contact at (128, 216),
	# offset by (0, -88) so that the ground contact sits at (0, 0) in Godot
	profile.offset = Vector2(0, -88)
	profile.flip_h_with_facing = true
	profile.anim_idle = &"idle"
	profile.anim_move = &"move"
	profile.anim_dash = &"dash"
	profile.anim_hit = &"hit"
	profile.anim_downed = &"downed"
	profile.anim_revive = &"revive"

	var err_prof := ResourceSaver.save(profile, PROFILE_PATH)
	if err_prof != OK:
		push_error("Failed to save %s: %d" % [PROFILE_PATH, err_prof])
	else:
		print("Saved %s" % PROFILE_PATH)

	print("Finished building production profile.")
	quit(0)
