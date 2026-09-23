extends SceneTree
## Focused verification suite for Penguin Wars Production Character Animation Import Contract.
## Tests directory layout, frame naming, canvas dimensions, 24 FPS baseline, loop/one-shot rules,
## Downed end-frame hold behavior, validator negative testing, and 4-player shared SpriteFrames usage.
## Exit code is nonzero on any failure.

const Validator = preload("res://scripts/tools/character_animation_validator.gd")
const PROD_PROFILE_PATH: String = "res://resources/characters/penguin_production_profile.tres"
const PROD_FRAMES_PATH: String = "res://resources/characters/penguin_production_sprite_frames.tres"
const PROD_DIR_PATH: String = "res://assets/characters/penguin/production"

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	print("--- BEGIN CHARACTER ANIMATION CONTRACT TESTS ---")

	# =========================================================================
	# 1. VALIDATOR NEGATIVE TESTING (VERIFY DETECTION OF INVALID EXPORTS)
	# =========================================================================
	print("Testing validator negative cases...")
	var bad_frames := SpriteFrames.new()
	if bad_frames.has_animation("default"):
		bad_frames.remove_animation("default")

	# Test 1a: Missing canonical animation
	bad_frames.add_animation("idle")
	bad_frames.set_animation_speed("idle", 24.0)
	bad_frames.set_animation_loop("idle", true)
	# Add a dummy texture to idle
	var dummy_img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var dummy_tex := ImageTexture.create_from_image(dummy_img)
	bad_frames.add_frame("idle", dummy_tex)

	var errs_missing := Validator.validate_sprite_frames(bad_frames)
	var has_missing_err := false
	for e in errs_missing:
		if "missing canonical animation" in e.to_lower():
			has_missing_err = true
			break
	check(has_missing_err, "validator catches missing canonical animation")

	# Test 1b: Wrong FPS
	bad_frames.add_animation("move")
	bad_frames.set_animation_speed("move", 15.0) # Wrong FPS
	bad_frames.set_animation_loop("move", true)
	bad_frames.add_frame("move", dummy_tex)
	var errs_fps := Validator.validate_sprite_frames(bad_frames)
	var has_fps_err := false
	for e in errs_fps:
		if "wrong fps" in e.to_lower():
			has_fps_err = true
			break
	check(has_fps_err, "validator catches wrong FPS (!= 24.0)")

	# Test 1c: Wrong Loop Flag (idle should loop, downed should not)
	bad_frames.set_animation_speed("move", 24.0)
	bad_frames.add_animation("downed")
	bad_frames.set_animation_speed("downed", 24.0)
	bad_frames.set_animation_loop("downed", true) # Wrong! Downed must be false
	bad_frames.add_frame("downed", dummy_tex)
	var errs_loop := Validator.validate_sprite_frames(bad_frames)
	var has_loop_err := false
	for e in errs_loop:
		if "wrong loop flag" in e.to_lower():
			has_loop_err = true
			break
	check(has_loop_err, "validator catches wrong loop flag on downed")

	# Test 1d: Inconsistent frame dimensions
	var bad_dim_img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var bad_dim_tex := ImageTexture.create_from_image(bad_dim_img)
	bad_frames.add_frame("idle", bad_dim_tex)
	var errs_dim := Validator.validate_sprite_frames(bad_frames, Vector2i(256, 256))
	var has_dim_err := false
	for e in errs_dim:
		if "dimension" in e.to_lower() or "match expected" in e.to_lower():
			has_dim_err = true
			break
	check(has_dim_err, "validator catches inconsistent frame dimensions")

	# =========================================================================
	# 2. PRODUCTION DIRECTORY LAYOUT & NAMING VALIDATION
	# =========================================================================
	print("Validating production directory layout...")
	var dir_errors := Validator.validate_directory(PROD_DIR_PATH, Vector2i(256, 256))
	for e in dir_errors:
		push_error("DIR VALIDATION ERROR: " + e)
	check(dir_errors.is_empty(), "production directory passes validation with 0 errors")

	# =========================================================================
	# 3. PRODUCTION SPRITEFRAMES RESOURCE VALIDATION
	# =========================================================================
	print("Validating production SpriteFrames resource...")
	var prod_frames := load(PROD_FRAMES_PATH) as SpriteFrames
	check(prod_frames != null, "production SpriteFrames resource loaded successfully")

	var frames_errors := Validator.validate_sprite_frames(prod_frames, Vector2i(256, 256))
	for e in frames_errors:
		push_error("FRAMES VALIDATION ERROR: " + e)
	check(frames_errors.is_empty(), "production SpriteFrames resource passes validation with 0 errors")

	# Verify specific properties
	check(prod_frames.get_animation_loop("idle") == true, "idle loop is true")
	check(prod_frames.get_animation_loop("move") == true, "move loop is true")
	check(prod_frames.get_animation_loop("dash") == false, "dash loop is false")
	check(prod_frames.get_animation_loop("hit") == false, "hit loop is false")
	check(prod_frames.get_animation_loop("downed") == false, "downed loop is false")
	check(prod_frames.get_animation_loop("revive") == false, "revive loop is false")

	check(prod_frames.get_animation_speed("idle") == 24.0, "idle speed is 24.0 FPS")
	check(prod_frames.get_animation_speed("move") == 24.0, "move speed is 24.0 FPS")
	check(prod_frames.get_animation_speed("dash") == 24.0, "dash speed is 24.0 FPS")
	check(prod_frames.get_animation_speed("hit") == 24.0, "hit speed is 24.0 FPS")
	check(prod_frames.get_animation_speed("downed") == 24.0, "downed speed is 24.0 FPS")
	check(prod_frames.get_animation_speed("revive") == 24.0, "revive speed is 24.0 FPS")

	# =========================================================================
	# 4. PRODUCTION PROFILE BINDING
	# =========================================================================
	print("Validating production CharacterPresentationProfile...")
	var prod_profile := load(PROD_PROFILE_PATH) as CharacterPresentationProfile
	check(prod_profile != null, "production CharacterPresentationProfile loaded successfully")

	var profile_errors := Validator.validate_profile(prod_profile, Vector2i(256, 256))
	for e in profile_errors:
		push_error("PROFILE VALIDATION ERROR: " + e)
	check(profile_errors.is_empty(), "production profile passes validation with 0 errors")

	check(prod_profile.base_scale == Vector2(0.25, 0.25), "profile base scale is 0.25 (64px height)")
	check(prod_profile.offset == Vector2(0, -88), "profile offset aligns anchor at (0, -88)")
	check(prod_profile.flip_h_with_facing == true, "profile flip_h_with_facing is true")

	# =========================================================================
	# 5. DOWNED END-FRAME HOLD BEHAVIOR VERIFICATION
	# =========================================================================
	print("Testing Downed end-frame hold behavior...")
	var scene: PackedScene = load("res://scenes/arena/test_arena.tscn")
	var arena: Node2D = scene.instantiate()
	root.add_child(arena)
	await process_frame

	var party: PartyRoster = arena.party
	var session: RunSession = RunSession.new()
	session.party = party
	session.wallet = arena.get_node("Wallet")
	session.progression = arena.progression
	session.encounter = arena.encounter
	session.loot = arena.get_node("Loot")
	session.builder = arena.get_node("Builder")
	session.camera = arena.get_node("Camera")
	session.actor_root = arena.get_node("Actors")

	# Ensure 4 players are present
	var players: Array[PenguinPlayer] = party.members()
	if players.size() < 4:
		for idx in range(players.size(), 4):
			var extra: PenguinPlayer = RunSession.PLAYER_SCENE.instantiate() as PenguinPlayer
			extra.identity = PlayerIdentity.new()
			extra.identity.player_id = idx + 1
			extra.identity.local_slot = idx
			extra.identity.device_id = idx
			var cdef: CharacterDefinition = session.roster[idx % session.roster.size()]
			if cdef != null:
				extra.identity.tint = cdef.tint
				extra.identity.character_id = cdef.id
			arena.get_node("Actors").add_child(extra)
			party.register(extra)

	players = party.members()
	var p1: PenguinPlayer = players[0]
	var v1: CharacterVisual = p1.get_node("CharacterVisual") as CharacterVisual

	# Bind production profile to P1
	v1.set_profile(prod_profile)
	check(v1._using_profile() == true, "P1 using production profile")
	p1.velocity = Vector2.ZERO
	v1._process_player(0.016)
	check(v1.animated_sprite.animation == &"idle", "P1 initially playing 'idle'")

	# Kill P1
	p1.health.take_damage(DamageEvent.new(1000))
	p1.dash.tick(0.016, Vector2.ZERO, false, false)
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.DOWNED, "P1 entered DOWNED")
	check(v1.animated_sprite.animation == &"downed", "P1 playing 'downed'")

	# Fast-forward animation to the final frame
	var total_downed_frames: int = prod_frames.get_frame_count("downed")
	v1.animated_sprite.frame = total_downed_frames - 1
	v1.animated_sprite.pause() # Simulates animation reaching completion

	# Process 20 frames while dead — verify frame does NOT reset to 0 or restart
	for step in range(20):
		v1._process_player(0.016)
		check(v1.animated_sprite.frame == total_downed_frames - 1, "Downed holds final settled frame without restarting (step %d)" % step)

	# Revive P1
	p1.health.revive(50.0)
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.REVIVE, "P1 transitions to REVIVE")
	check(v1.animated_sprite.animation == &"revive", "P1 playing 'revive'")

	# Settle revive to IDLE
	v1._process_player(0.40)
	check(v1.current_state == CharacterVisual.State.IDLE, "P1 settles back into IDLE")
	check(v1.animated_sprite.animation == &"idle", "P1 returned to 'idle'")

	# =========================================================================
	# 6. MULTIPLAYER WITH SHARED PRODUCTION SPRITEFRAMES (4 PLAYERS)
	# =========================================================================
	print("Testing 4-player shared production profile usage...")
	var p2: PenguinPlayer = players[1]
	var p3: PenguinPlayer = players[2]
	var p4: PenguinPlayer = players[3]
	var v2: CharacterVisual = p2.get_node("CharacterVisual") as CharacterVisual
	var v3: CharacterVisual = p3.get_node("CharacterVisual") as CharacterVisual
	var v4: CharacterVisual = p4.get_node("CharacterVisual") as CharacterVisual

	v2.set_profile(prod_profile)
	v3.set_profile(prod_profile)
	v4.set_profile(prod_profile)

	for p in [p1, p2, p3, p4]:
		p.velocity = Vector2.ZERO
	v1._process_player(0.016)
	v2._process_player(0.016)
	v3._process_player(0.016)
	v4._process_player(0.016)

	# Distinct states active across players simultaneously using the SAME SpriteFrames resource
	p1.velocity = Vector2(100, 0) # P1 MOVE
	p2.dash.remaining = 0.16      # P2 DASH
	p3.health.take_damage(DamageEvent.new(10)) # P3 HIT
	# P4 remains IDLE

	v1._process_player(0.016)
	v2._process_player(0.016)
	v3._process_player(0.016)
	v4._process_player(0.016)

	check(v1.current_state == CharacterVisual.State.MOVE, "P1 is MOVE")
	check(v1.animated_sprite.animation == &"move", "P1 playing 'move'")

	check(v2.current_state == CharacterVisual.State.DASH, "P2 is DASH")
	check(v2.animated_sprite.animation == &"dash", "P2 playing 'dash'")

	check(v3.current_state == CharacterVisual.State.HIT, "P3 is HIT")
	check(v3.animated_sprite.animation == &"hit", "P3 playing 'hit'")

	check(v4.current_state == CharacterVisual.State.IDLE, "P4 is IDLE")
	check(v4.animated_sprite.animation == &"idle", "P4 playing 'idle'")

	# Clean up
	arena.free()

	print("--- CHARACTER ANIMATION CONTRACT TESTS FINISHED ---")
	print("RESULT: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
