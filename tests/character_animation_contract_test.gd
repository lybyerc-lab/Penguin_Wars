extends SceneTree
## Comprehensive acceptance test suite for Penguin Wars Production Character Animation Import Contract v1.1.
## Tests centralized contract values, directory layout, base/scarf layer synchronization,
## per-player scarf tinting, one-shot presentation timing & recovery, Downed end-frame hold,
## repeated hit replay, authoritative death interruption, and 4-player shared resource independence.
## Exit code is nonzero on any failure.

const Contract = preload("res://scripts/data/character_animation_contract.gd")
const Validator = preload("res://scripts/tools/character_animation_validator.gd")
const ProfileScript = preload("res://scripts/data/character_presentation_profile.gd")

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
	# 1. CENTRALIZED CONTRACT VALUES VERIFICATION
	# =========================================================================
	print("1. Verifying centralized contract constants...")
	check(Contract.CANVAS_SIZE == Vector2i(256, 256), "Contract CANVAS_SIZE is 256x256")
	check(Contract.GROUND_ANCHOR == Vector2i(128, 216), "Contract GROUND_ANCHOR is (128, 216)")
	check(is_equal_approx(Contract.SOURCE_FPS, 24.0), "Contract SOURCE_FPS is 24.0")
	check(Contract.RUNTIME_SCALE == Vector2(0.25, 0.25), "Contract RUNTIME_SCALE is (0.25, 0.25)")
	check(Contract.RUNTIME_OFFSET == Vector2(0.0, -88.0), "Contract RUNTIME_OFFSET is (0, -88)")
	check(Contract.CANONICAL_STATES.size() == 6, "Contract defines exactly 6 canonical states")
	check(Contract.is_state_looping("idle") == true, "Contract idle loops")
	check(Contract.is_state_looping("move") == true, "Contract move loops")
	check(Contract.is_state_looping("dash") == false, "Contract dash is one-shot")
	check(Contract.is_state_looping("hit") == false, "Contract hit is one-shot")
	check(Contract.is_state_looping("downed") == false, "Contract downed is one-shot")
	check(Contract.is_state_looping("revive") == false, "Contract revive is one-shot")
	check(Contract.REQUIRED_LAYERS.has("base") and Contract.REQUIRED_LAYERS.has("scarf"), "Contract requires 'base' and 'scarf' layers")

	# =========================================================================
	# 2. VALIDATOR NEGATIVE TESTING
	# =========================================================================
	print("2. Testing validator negative cases...")
	var bad_frames := SpriteFrames.new()
	if bad_frames.has_animation("default"):
		bad_frames.remove_animation("default")

	# 2a: Missing canonical animation
	bad_frames.add_animation("idle")
	bad_frames.set_animation_speed("idle", 24.0)
	bad_frames.set_animation_loop("idle", true)
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

	# 2b: Wrong FPS
	bad_frames.add_animation("move")
	bad_frames.set_animation_speed("move", 15.0)
	bad_frames.set_animation_loop("move", true)
	bad_frames.add_frame("move", dummy_tex)
	var errs_fps := Validator.validate_sprite_frames(bad_frames)
	var has_fps_err := false
	for e in errs_fps:
		if "wrong fps" in e.to_lower():
			has_fps_err = true
			break
	check(has_fps_err, "validator catches wrong FPS (!= 24.0)")

	# 2c: Wrong Loop Flag
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

	# 2d: Inconsistent frame dimensions
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

	# 2e: Rejection of art/blender path
	var blender_errs := Validator.validate_directory_layout("res://art/blender/characters/penguin")
	var has_blender_err := false
	for e in blender_errs:
		if "art/blender" in e or "art\\blender" in e:
			has_blender_err = true
			break
	check(has_blender_err, "validator rejects attempts to load runtime assets from art/blender/")

	# =========================================================================
	# 3. REAL PRODUCTION FRAMES VALIDATION
	# =========================================================================
	print("3. Validating real production frames and exact approved export counts...")
	var production_errors := Validator.validate_directory_layout(Contract.PATH_PRODUCTION_ROOT)
	for e in production_errors:
		push_error("PRODUCTION DIR ERROR: " + e)
	check(production_errors.is_empty(), "real production frame directory passes validation")
	var expected_counts := {"idle": 40, "move": 16, "dash": 10, "hit": 7, "downed": 14, "revive": 14}
	var fixture_pngs: Array[String] = []
	_scan_for_pngs(Contract.PATH_FIXTURE_ROOT, fixture_pngs)
	var fixture_hashes: Dictionary = {}
	for fixture_path in fixture_pngs:
		fixture_hashes[FileAccess.get_sha256(fixture_path)] = true
	for layer in Contract.REQUIRED_LAYERS:
		for state_name in Contract.CANONICAL_STATES:
			var state_dir := DirAccess.open("%s/%s/%s" % [Contract.PATH_PRODUCTION_ROOT, layer, state_name])
			check(state_dir != null, "%s/%s directory exists" % [layer, state_name])
			if state_dir != null:
				var png_count := 0
				for file_name in state_dir.get_files():
					if file_name.ends_with(".png"):
						png_count += 1
						var production_path := "%s/%s/%s/%s" % [Contract.PATH_PRODUCTION_ROOT, layer, state_name, file_name]
						check(not fixture_hashes.has(FileAccess.get_sha256(production_path)), "production %s/%s contains no fixture frame %s" % [layer, state_name, file_name])
				check(png_count == expected_counts[state_name], "%s/%s has exactly %d real frames" % [layer, state_name, expected_counts[state_name]])
	var production_profile := load(Contract.PATH_PRODUCTION_PROFILE) as CharacterPresentationProfile
	check(production_profile != null, "real production profile loads")
	if production_profile != null:
		var production_profile_errors := Validator.validate_profile(production_profile)
		for e in production_profile_errors:
			push_error("PRODUCTION PROFILE ERROR: " + e)
		check(production_profile_errors.is_empty(), "real production profile passes validation")
		for state_name in Contract.CANONICAL_STATES:
			check(production_profile.sprite_frames.get_frame_count(state_name) == expected_counts[state_name], "compiled base %s count matches source" % state_name)
			check(production_profile.scarf_sprite_frames.get_frame_count(state_name) == expected_counts[state_name], "compiled scarf %s count matches source" % state_name)
	# =========================================================================
	# 4. DIAGNOSTIC FIXTURE DIRECTORY VALIDATION
	# =========================================================================
	print("4. Validating diagnostic fixture directory layout...")
	var fixture_dir_errs := Validator.validate_directory_layout(Contract.PATH_FIXTURE_ROOT)
	for e in fixture_dir_errs:
		push_error("FIXTURE DIR ERROR: " + e)
	check(fixture_dir_errs.is_empty(), "diagnostic fixtures directory passes validation with 0 errors")

	# =========================================================================
	# 5. COMPILED FIXTURE SPRITEFRAMES & PROFILE RESOURCES VALIDATION
	# =========================================================================
	print("5. Validating fixture SpriteFrames & Profile resources...")
	var fixture_base_frames := load(Contract.PATH_FIXTURE_SPRITE_FRAMES) as SpriteFrames
	check(fixture_base_frames != null, "fixture base SpriteFrames loaded successfully")
	var base_frame_errs := Validator.validate_sprite_frames(fixture_base_frames)
	for e in base_frame_errs:
		push_error("BASE FRAMES ERROR: " + e)
	check(base_frame_errs.is_empty(), "fixture base SpriteFrames passes validation with 0 errors")

	var fixture_scarf_frames := load(Contract.PATH_FIXTURE_SCARF_FRAMES) as SpriteFrames
	check(fixture_scarf_frames != null, "fixture scarf SpriteFrames loaded successfully")
	var scarf_frame_errs := Validator.validate_sprite_frames(fixture_scarf_frames)
	for e in scarf_frame_errs:
		push_error("SCARF FRAMES ERROR: " + e)
	check(scarf_frame_errs.is_empty(), "fixture scarf SpriteFrames passes validation with 0 errors")

	var fixture_profile := load(Contract.PATH_FIXTURE_PROFILE) as CharacterPresentationProfile
	check(fixture_profile != null, "fixture CharacterPresentationProfile loaded successfully")
	var prof_errs := Validator.validate_profile(fixture_profile)
	for e in prof_errs:
		push_error("PROFILE ERROR: " + e)
	check(prof_errs.is_empty(), "fixture CharacterPresentationProfile passes validation with 0 errors")

	# Verify canonical loop flags & speeds
	for state_name in Contract.CANONICAL_STATES:
		var exp_loop: bool = Contract.is_state_looping(state_name)
		check(fixture_base_frames.get_animation_loop(state_name) == exp_loop, "base %s loop flag is %s" % [state_name, exp_loop])
		check(fixture_scarf_frames.get_animation_loop(state_name) == exp_loop, "scarf %s loop flag is %s" % [state_name, exp_loop])
		check(is_equal_approx(fixture_base_frames.get_animation_speed(state_name), 24.0), "base %s speed is 24.0 fps" % state_name)
		check(is_equal_approx(fixture_scarf_frames.get_animation_speed(state_name), 24.0), "scarf %s speed is 24.0 fps" % state_name)

	# Verify arbitrary frame count support in fixture:
	check(fixture_base_frames.get_frame_count("idle") == 4, "fixture idle has 4 frames")
	check(fixture_base_frames.get_frame_count("move") == 8, "fixture move has 8 frames")
	check(fixture_base_frames.get_frame_count("dash") == 4, "fixture dash has 4 frames")
	check(fixture_base_frames.get_frame_count("hit") == 6, "fixture hit has 6 frames (0.25s at 24fps)")
	check(fixture_base_frames.get_frame_count("downed") == 6, "fixture downed has 6 frames")
	check(fixture_base_frames.get_frame_count("revive") == 6, "fixture revive has 6 frames")

	# =========================================================================
	# 6. ARENA SETUP WITH 4 PLAYERS USING FIXTURE PROFILE
	# =========================================================================
	print("6. Setting up 4-player test arena with fixture profile...")
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
	var p2: PenguinPlayer = players[1]
	var p3: PenguinPlayer = players[2]
	var p4: PenguinPlayer = players[3]

	var v1: CharacterVisual = p1.get_node("CharacterVisual") as CharacterVisual
	var v2: CharacterVisual = p2.get_node("CharacterVisual") as CharacterVisual
	var v3: CharacterVisual = p3.get_node("CharacterVisual") as CharacterVisual
	var v4: CharacterVisual = p4.get_node("CharacterVisual") as CharacterVisual

	# The real production profile is the default runtime binding before
	# this test deliberately switches to the diagnostic fixture.
	for visual in [v1, v2, v3, v4]:
		check(visual.profile == production_profile, "player scene defaults to real production profile")

	# Bind fixture profile to all 4 players
	v1.set_profile(fixture_profile)
	v2.set_profile(fixture_profile)
	v3.set_profile(fixture_profile)
	v4.set_profile(fixture_profile)

	for v in [v1, v2, v3, v4]:
		check(v._using_profile() == true, "CharacterVisual using profile")
		check(v.animated_sprite != null and v.animated_sprite.visible == true, "Base animated_sprite active")
		check(v.scarf_sprite != null and v.scarf_sprite.visible == true, "Scarf scarf_sprite active")

	# =========================================================================
	# 7. BASE + SCARF LAYER SYNCHRONIZATION & SCARF TINT INDEPENDENCE
	# =========================================================================
	print("7. Verifying base/scarf synchronization and scarf tinting...")
	p1.velocity = Vector2(100, 0) # Moving right
	v1._process_player(0.016)
	check(v1.animated_sprite.animation == &"move", "Base plays 'move'")
	check(v1.scarf_sprite.animation == &"move", "Scarf plays 'move'")
	check(v1.animated_sprite.flip_h == false, "Base flip_h false when moving right")
	check(v1.scarf_sprite.flip_h == false, "Scarf flip_h false when moving right")
	check(v1.animated_sprite.frame == v1.scarf_sprite.frame, "Base and scarf frame index match")

	p1.velocity = Vector2(-100, 0) # Moving left
	v1._process_player(0.016)
	check(v1.animated_sprite.flip_h == true, "Base flip_h true when moving left")
	check(v1.scarf_sprite.flip_h == true, "Scarf flip_h true when moving left")
	check(v1.animated_sprite.frame == v1.scarf_sprite.frame, "Base and scarf frame index match after flip")

	# Per-player scarf tint: scarf is tinted, base body is NOT tinted
	check(v1.scarf_sprite.modulate == p1.identity.tint, "P1 scarf tinted with P1 identity tint")
	check(v1.animated_sprite.modulate == Color.WHITE, "P1 base body sprite is WHITE (untinted)")
	check(v2.scarf_sprite.modulate == p2.identity.tint, "P2 scarf tinted with P2 identity tint")
	check(v2.animated_sprite.modulate == Color.WHITE, "P2 base body sprite is WHITE (untinted)")
	check(v1.scarf_sprite.modulate != v2.scarf_sprite.modulate, "P1 and P2 scarfs have distinct tints")

	# =========================================================================
	# 8. ONE-SHOT PRESENTATION TIMING: HIT (24 FPS, 6 FRAMES = 0.25S)
	# =========================================================================
	print("8. Verifying HIT presentation timing (not truncated by old 0.18s)...")
	p1.velocity = Vector2.ZERO
	v1._process_player(0.016) # Back to idle
	check(v1.current_state == CharacterVisual.State.IDLE, "P1 is IDLE")

	p1.health.take_damage(DamageEvent.new(10)) # Triggers HIT
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.HIT, "Taking damage enters HIT state")
	check(v1.animated_sprite.animation == &"hit", "Base plays 'hit'")
	check(v1.scarf_sprite.animation == &"hit", "Scarf plays 'hit'")

	# Advance 0.19 seconds (total elapsed > 0.18s older constant)
	v1._process_player(0.18)
	# Production hit has 6 frames / 24 fps = 0.25s duration. At ~0.196s it must STILL be in HIT!
	check(v1.current_state == CharacterVisual.State.HIT, "HIT is NOT truncated at 0.18s constant (still in HIT at >0.18s)")

	# Advance past 0.26s total -> HIT completes and recovers to IDLE
	v1._process_player(0.08)
	check(v1.current_state == CharacterVisual.State.IDLE, "HIT presentation recovers cleanly to IDLE after 0.25s completes")
	check(v1.animated_sprite.animation == &"idle", "Base returned to 'idle'")
	check(v1.scarf_sprite.animation == &"idle", "Scarf returned to 'idle'")

	# =========================================================================
	# 9. REPEATED HIT RESTART BEHAVIOR
	# =========================================================================
	print("9. Verifying repeated HIT restarts animation from frame 0...")
	p1.health.take_damage(DamageEvent.new(10))
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.HIT, "First hit entered HIT")
	v1.animated_sprite.frame = 3 # Mid-way through animation
	v1.scarf_sprite.frame = 3

	# Second damage event occurs while in HIT
	p1.health.take_damage(DamageEvent.new(10))
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.HIT, "Still in HIT after second damage event")
	check(v1.animated_sprite.frame == 0, "Second damage event restarted base animation from frame 0")
	check(v1.scarf_sprite.frame == 0, "Second damage event restarted scarf animation from frame 0")

	# Let hit expire
	v1._process_player(0.30)
	check(v1.current_state == CharacterVisual.State.IDLE, "Hit recovers to IDLE")

	# =========================================================================
	# 10. DASH ONE-SHOT PRESENTATION RELEASE
	# =========================================================================
	print("10. Verifying DASH one-shot releases cleanly...")
	p1.dash.direction = Vector2.RIGHT
	p1.dash.remaining = 0.16
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.DASH, "Starting dash triggers visual DASH state")
	check(v1.animated_sprite.animation == &"dash", "Base plays 'dash'")
	check(v1.scarf_sprite.animation == &"dash", "Scarf plays 'dash'")

	# Dash animation completes (4 frames / 24 fps = 0.167s)
	p1.dash.remaining = 0.0
	p1.velocity = Vector2.ZERO
	v1._process_player(0.20)
	check(v1.current_state == CharacterVisual.State.IDLE, "DASH releases presentation cleanly to IDLE")
	check(v1.animated_sprite.animation == &"idle", "Base returned to 'idle'")
	check(v1.scarf_sprite.animation == &"idle", "Scarf returned to 'idle'")

	# =========================================================================
	# 11. DOWNED END-FRAME HOLD (NO REPLAYING OR LOOPING)
	# =========================================================================
	print("11. Verifying DOWNED holds final frame indefinitely...")
	p1.health.take_damage(DamageEvent.new(1000)) # Lethal damage
	p1.dash.remaining = 0.0
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.DOWNED, "Lethal damage triggers DOWNED")
	check(v1.animated_sprite.animation == &"downed", "Base plays 'downed'")
	check(v1.scarf_sprite.animation == &"downed", "Scarf plays 'downed'")

	# Advance to final frame (frame 5 of 6)
	v1.animated_sprite.frame = 5
	v1.scarf_sprite.frame = 5
	v1.animated_sprite.pause()
	v1.scarf_sprite.pause()

	# Process 25 ticks while dead — ensure frame remains locked at frame 5
	for step in range(25):
		v1._process_player(0.016)
		check(v1.animated_sprite.frame == 5, "Base downed holds settled final frame at step %d" % step)
		check(v1.scarf_sprite.frame == 5, "Scarf downed holds settled final frame at step %d" % step)
		check(v1.current_state == CharacterVisual.State.DOWNED, "State remains DOWNED at step %d" % step)

	# =========================================================================
	# 12. REVIVE ONE-SHOT COMPLETION BEFORE RETURNING TO IDLE
	# =========================================================================
	print("12. Verifying REVIVE one-shot completes before returning to IDLE...")
	p1.health.revive(50.0)
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.REVIVE, "Reviving enters REVIVE state")
	check(v1.animated_sprite.animation == &"revive", "Base plays 'revive'")
	check(v1.scarf_sprite.animation == &"revive", "Scarf plays 'revive'")

	# At 0.15s into revive (6 frames / 24 fps = 0.25s total), still in REVIVE
	v1._process_player(0.12)
	check(v1.current_state == CharacterVisual.State.REVIVE, "Still in REVIVE mid-sequence")

	# After 0.30s total, revive completes -> IDLE
	v1._process_player(0.20)
	check(v1.current_state == CharacterVisual.State.IDLE, "REVIVE completes and returns to IDLE")
	check(v1.animated_sprite.animation == &"idle", "Base returned to 'idle'")

	# =========================================================================
	# 13. AUTHORITATIVE DEATH IMMEDIATELY OVERRIDES LIVE PRESENTATION
	# =========================================================================
	print("13. Verifying authoritative death interrupts live presentation immediately...")
	p1.dash.direction = Vector2.RIGHT
	p1.dash.remaining = 0.16
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.DASH, "Player entered DASH")

	# Kill player while in DASH
	p1.health.take_damage(DamageEvent.new(1000))
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.DOWNED, "Death immediately overrides active DASH")
	check(v1.animated_sprite.animation == &"downed", "Base immediately plays 'downed'")
	check(v1.scarf_sprite.animation == &"downed", "Scarf immediately plays 'downed'")

	# =========================================================================
	# 14. 4-PLAYER SHARED RESOURCE INDEPENDENCE
	# =========================================================================
	print("14. Verifying 4-player simultaneous independent state with shared profile...")
	p1.dash.remaining = 0.0
	p1.health.revive(100.0)
	v1._process_player(0.30) # Settle P1 to IDLE

	for p in [p1, p2, p3, p4]:
		p.velocity = Vector2.ZERO
	v1._process_player(0.016)
	v2._process_player(0.016)
	v3._process_player(0.016)
	v4._process_player(0.016)

	p1.velocity = Vector2(100, 0)             # P1: MOVE
	p2.dash.remaining = 0.16                  # P2: DASH
	p3.health.take_damage(DamageEvent.new(10))# P3: HIT
	# P4: remains IDLE

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

	# =========================================================================
	# 15. REAL PRODUCTION PROFILE IN THE SAME 4-PLAYER ARENA
	# =========================================================================
	print("15. Verifying real production profile, state independence, and scarf tint...")
	var production_visuals: Array[CharacterVisual] = [v1, v2, v3, v4]
	var production_players: Array[PenguinPlayer] = [p1, p2, p3, p4]
	for i in range(4):
		var visual := production_visuals[i]
		var player := production_players[i]
		var actor_position := player.global_position
		var rack_position := player.weapon_rack.position
		visual.set_profile(production_profile)
		visual._process_player(0.0)
		check(player.global_position == actor_position, "P%d animation leaves gameplay position unchanged" % (i + 1))
		check(player.weapon_rack.position == rack_position, "P%d animation leaves weapon rack origin unchanged" % (i + 1))
		check(visual.profile == production_profile, "P%d uses real production profile" % (i + 1))
		check(visual.animated_sprite.sprite_frames == production_profile.sprite_frames, "P%d shares base frames resource" % (i + 1))
		check(visual.scarf_sprite.sprite_frames == production_profile.scarf_sprite_frames, "P%d shares scarf frames resource" % (i + 1))
		check(visual.animated_sprite.modulate == Color.WHITE, "P%d body remains untinted" % (i + 1))
		check(visual.scarf_sprite.modulate == player.identity.tint, "P%d scarf has its identity tint" % (i + 1))
		check(visual.animated_sprite.frame == visual.scarf_sprite.frame, "P%d base/scarf frame sync" % (i + 1))
		var collision := player.get_node("CollisionShape2D") as CollisionShape2D
		check(collision != null and collision.shape is CircleShape2D and is_equal_approx(collision.shape.radius, 16.0), "P%d gameplay collision remains unchanged" % (i + 1))
	for i in range(4):
		for j in range(i + 1, 4):
			check(production_visuals[i].scarf_sprite.modulate != production_visuals[j].scarf_sprite.modulate, "P%d and P%d scarf colors differ" % [i + 1, j + 1])
	check(v1.animated_sprite.animation == &"move", "real P1 remains MOVE")
	check(v2.animated_sprite.animation == &"dash", "real P2 remains DASH")
	check(v3.animated_sprite.animation == &"hit", "real P3 remains HIT")
	check(v4.animated_sprite.animation == &"idle", "real P4 remains IDLE")
	check(is_equal_approx(v1.get_state_animation_duration(CharacterVisual.State.HIT), 7.0 / 24.0), "real Hit uses seven-frame duration")
	check(is_equal_approx(v1.get_state_animation_duration(CharacterVisual.State.REVIVE), 14.0 / 24.0), "real Revive uses fourteen-frame duration")
	check(not production_profile.sprite_frames.get_animation_loop(&"downed"), "real Downed plays once and holds")
	check(not production_profile.sprite_frames.get_animation_loop(&"revive"), "real Revive plays once")

	# Clean up
	arena.free()

	print("--- CHARACTER ANIMATION CONTRACT TESTS FINISHED ---")
	print("RESULT: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

static func _scan_for_pngs(path: String, result: Array[String]) -> void:
	var da := DirAccess.open(path)
	if da == null:
		return
	da.list_dir_begin()
	var fname := da.get_next()
	while fname != "":
		if da.current_is_dir() and fname != "." and fname != "..":
			_scan_for_pngs("%s/%s" % [path, fname], result)
		elif fname.ends_with(".png"):
			result.append("%s/%s" % [path, fname])
		fname = da.get_next()
	da.list_dir_end()
