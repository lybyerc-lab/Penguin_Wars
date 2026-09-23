extends SceneTree
## Focused verification suite for Penguin Wars Production Character Runtime Seam.
## Tests CharacterPresentationProfile mapping, AnimatedSprite2D driving, fallback mode,
## 1-player and 4-player multiplayer independence, collision and weapon rack isolation.
## Exit code is nonzero on any failure.

const CharacterPresentationProfileScript = preload("res://scripts/data/character_presentation_profile.gd")
const TEMPORARY_PROFILE_PATH: String = "res://resources/characters/penguin_temporary_profile.tres"

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	print("--- BEGIN CHARACTER PRESENTATION SEAM TESTS ---")

	# =========================================================================
	# 1. PROFILE RESOURCE AND ANIMATION MAPPING
	# =========================================================================
	var profile := load(TEMPORARY_PROFILE_PATH) as CharacterPresentationProfileScript
	check(profile != null, "temporary profile loads successfully")
	check(profile.profile_name.length() > 0, "profile has valid name")
	check(profile.sprite_frames != null, "profile contains SpriteFrames")

	check(profile.get_animation_for_state(CharacterVisual.State.IDLE) == &"idle", "maps IDLE to 'idle'")
	check(profile.get_animation_for_state(CharacterVisual.State.MOVE) == &"move", "maps MOVE to 'move'")
	check(profile.get_animation_for_state(CharacterVisual.State.WADDLE) == &"move", "maps WADDLE alias to 'move'")
	check(profile.get_animation_for_state(CharacterVisual.State.DASH) == &"dash", "maps DASH to 'dash'")
	check(profile.get_animation_for_state(CharacterVisual.State.HIT) == &"hit", "maps HIT to 'hit'")
	check(profile.get_animation_for_state(CharacterVisual.State.DOWNED) == &"downed", "maps DOWNED to 'downed'")
	check(profile.get_animation_for_state(CharacterVisual.State.KO) == &"downed", "maps KO alias to 'downed'")
	check(profile.get_animation_for_state(CharacterVisual.State.REVIVE) == &"revive", "maps REVIVE to 'revive'")

	check(profile.has_animation(&"idle"), "profile SpriteFrames has 'idle'")
	check(profile.has_animation(&"move"), "profile SpriteFrames has 'move'")
	check(profile.has_animation(&"dash"), "profile SpriteFrames has 'dash'")
	check(profile.has_animation(&"hit"), "profile SpriteFrames has 'hit'")
	check(profile.has_animation(&"downed"), "profile SpriteFrames has 'downed'")
	check(profile.has_animation(&"revive"), "profile SpriteFrames has 'revive'")

	# =========================================================================
	# 2. ARENA SETUP WITH 4 PLAYERS
	# =========================================================================
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

	# Ensure 4 players are present in the arena
	var players: Array[PenguinPlayer] = party.members()
	if players.size() < 4:
		# Add remaining players up to 4
		for idx in range(players.size(), 4):
			var extra_player: PenguinPlayer = RunSession.PLAYER_SCENE.instantiate() as PenguinPlayer
			extra_player.identity = PlayerIdentity.new()
			extra_player.identity.player_id = idx + 1
			extra_player.identity.local_slot = idx
			extra_player.identity.device_id = idx
			var char_def: CharacterDefinition = session.roster[idx % session.roster.size()]
			if char_def != null:
				extra_player.identity.tint = char_def.tint
				extra_player.identity.character_id = char_def.id
			arena.get_node("Actors").add_child(extra_player)
			party.register(extra_player)

	players = party.members()
	check(players.size() >= 4, "party has 4 active players for multiplayer verification")

	var p1: PenguinPlayer = players[0]
	var p2: PenguinPlayer = players[1]
	var p3: PenguinPlayer = players[2]
	var p4: PenguinPlayer = players[3]

	var v1: CharacterVisual = p1.get_node_or_null("CharacterVisual") as CharacterVisual
	var v2: CharacterVisual = p2.get_node_or_null("CharacterVisual") as CharacterVisual
	var v3: CharacterVisual = p3.get_node_or_null("CharacterVisual") as CharacterVisual
	var v4: CharacterVisual = p4.get_node_or_null("CharacterVisual") as CharacterVisual

	check(v1 != null and v2 != null and v3 != null and v4 != null, "all 4 players have CharacterVisual nodes")
	check(v1 != v2 and v2 != v3 and v3 != v4, "all CharacterVisual instances are distinct and unique")

	# =========================================================================
	# 3. ONE PLAYER CANONICAL STATE DRIVING VIA PROFILE SEAM (AnimatedSprite2D)
	# =========================================================================
	v1.set_profile(profile)
	check(v1._using_profile() == true, "P1 is using profile presentation mode")
	check(v1.animated_sprite != null and v1.animated_sprite.visible == true, "AnimatedSprite2D is active and visible")

	# Initial: IDLE
	p1.velocity = Vector2.ZERO
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.IDLE, "stationary player is IDLE")
	check(v1.animated_sprite.animation == &"idle", "AnimatedSprite2D plays 'idle'")

	# Movement: MOVE
	p1.velocity = Vector2(120, 0)
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.MOVE, "velocity > 10 activates MOVE state")
	check(v1.animated_sprite.animation == &"move", "AnimatedSprite2D plays 'move'")
	check(v1.animated_sprite.flip_h == false, "moving right faces right (flip_h == false)")

	# Moving left flips facing
	p1.velocity = Vector2(-120, 0)
	v1._process_player(0.016)
	check(v1.animated_sprite.flip_h == true, "moving left faces left (flip_h == true)")

	# Settle back to IDLE
	p1.velocity = Vector2.ZERO
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.IDLE, "stopping returns cleanly to IDLE")
	check(v1.animated_sprite.animation == &"idle", "returns to 'idle' animation")

	# Dash: DASH
	p1.dash.direction = Vector2.RIGHT
	p1.dash.remaining = 0.16
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.DASH, "dash.is_active() triggers DASH state")
	check(v1.animated_sprite.animation == &"dash", "AnimatedSprite2D plays 'dash'")
	check(v1.animated_sprite.flip_h == false, "dash right faces right")

	# Dash completion returns to IDLE (no stale dash)
	p1.dash.remaining = 0.0
	p1.velocity = Vector2.ZERO
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.IDLE, "dash completion returns to IDLE")
	check(v1.animated_sprite.animation == &"idle", "no stale dash animation remains stuck")

	# Damage: HIT
	p1.health.take_damage(DamageEvent.new(15))
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.HIT, "taking non-lethal damage triggers HIT state")
	check(v1.animated_sprite.animation == &"hit", "AnimatedSprite2D plays 'hit'")

	# Hit recovery after HIT_DURATION (no stale hit)
	v1._process_player(0.22)
	check(v1.current_state == CharacterVisual.State.IDLE, "hit reaction recovers cleanly to IDLE")
	check(v1.animated_sprite.animation == &"idle", "no stale hit animation remains stuck")

	# Lethal Damage: DOWNED
	p1.health.take_damage(DamageEvent.new(1000))
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.DOWNED, "death enters DOWNED state")
	check(v1.animated_sprite.animation == &"downed", "AnimatedSprite2D plays 'downed'")
	check(v1._halo.visible == true, "halo is visible while DOWNED")

	# Revive: REVIVE
	var revived: bool = p1.health.revive(50.0)
	check(revived, "health.revive succeeds")
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.REVIVE, "revived signal triggers REVIVE state")
	check(v1.animated_sprite.animation == &"revive", "AnimatedSprite2D plays 'revive'")
	check(v1._halo.visible == false, "halo is hidden during REVIVE")

	# Revive completion returns to IDLE
	v1._process_player(0.40)
	check(v1.current_state == CharacterVisual.State.IDLE, "revive completion settles in IDLE")
	check(v1.animated_sprite.animation == &"idle", "returns to 'idle' animation")

	# =========================================================================
	# 3b. STATE PRIORITY HIERARCHY VERIFICATION (DOWNED > REVIVE > HIT > DASH > MOVE > IDLE)
	# =========================================================================
	# HIT overrides DASH
	p1.dash.remaining = 0.16
	p1.health.take_damage(DamageEvent.new(10))
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.HIT, "HIT takes priority over active DASH")
	v1._process_player(0.20)
	# After hit recovers, active dash still presents if remaining
	p1.dash.remaining = 0.10
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.DASH, "recovering from HIT while dash still active presents DASH")
	p1.dash.remaining = 0.0

	# DOWNED overrides active DASH and HIT
	p1.dash.direction = Vector2.RIGHT
	p1.dash.remaining = 0.16
	p1.health.take_damage(DamageEvent.new(1000))
	p1.dash.tick(0.016, Vector2.ZERO, false, p1.health.is_alive())
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.DOWNED, "DOWNED takes priority over active DASH and HIT")

	# REVIVE overrides DOWNED
	p1.health.revive(50.0)
	v1._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.REVIVE, "REVIVE takes priority over DOWNED")
	v1._process_player(0.40)
	check(v1.current_state == CharacterVisual.State.IDLE, "REVIVE completion settles in IDLE")

	# =========================================================================
	# 4. PROFILE SWAPPING AND FALLBACK PUPPET ADAPTER
	# =========================================================================
	v1.set_profile(null)
	check(v1._using_profile() == false, "setting profile null switches to fallback mode")
	check(v1.animated_sprite.visible == false, "AnimatedSprite2D is hidden in fallback mode")
	v1._process_player(0.016)
	check(v1._eyes.texture == CharacterVisual.TEX_EYES_ALERT, "fallback puppet eyes active")

	# Re-enable profile
	v1.set_profile(profile)
	check(v1._using_profile() == true, "reassigning profile switches back to profile mode")
	check(v1.animated_sprite.visible == true, "AnimatedSprite2D is visible again")

	# =========================================================================
	# 5. MULTIPLAYER INDEPENDENCE (4 PLAYERS)
	# =========================================================================
	# Configure all 4 players with profile presentation
	v2.set_profile(profile)
	v3.set_profile(profile)
	v4.set_profile(profile)

	for p in [p1, p2, p3, p4]:
		p.velocity = Vector2.ZERO
	v1._process_player(0.016)
	v2._process_player(0.016)
	v3._process_player(0.016)
	v4._process_player(0.016)

	check(v1.current_state == CharacterVisual.State.IDLE, "P1 is IDLE")
	check(v2.current_state == CharacterVisual.State.IDLE, "P2 is IDLE")
	check(v3.current_state == CharacterVisual.State.IDLE, "P3 is IDLE")
	check(v4.current_state == CharacterVisual.State.IDLE, "P4 is IDLE")

	# P1 dashes -> P2, P3, P4 unaffected
	p1.dash.direction = Vector2.RIGHT
	p1.dash.remaining = 0.16
	v1._process_player(0.016)
	v2._process_player(0.016)
	v3._process_player(0.016)
	v4._process_player(0.016)
	check(v1.current_state == CharacterVisual.State.DASH, "P1 is in DASH")
	check(v2.current_state == CharacterVisual.State.IDLE, "P2 unaffected by P1 dash")
	check(v3.current_state == CharacterVisual.State.IDLE, "P3 unaffected by P1 dash")
	check(v4.current_state == CharacterVisual.State.IDLE, "P4 unaffected by P1 dash")
	p1.dash.remaining = 0.0
	v1._process_player(0.016)

	# P2 is hit -> P1, P3, P4 unaffected
	p2.health.take_damage(DamageEvent.new(10))
	v1._process_player(0.016)
	v2._process_player(0.016)
	v3._process_player(0.016)
	v4._process_player(0.016)
	check(v2.current_state == CharacterVisual.State.HIT, "P2 is in HIT")
	check(v1.current_state == CharacterVisual.State.IDLE, "P1 unaffected by P2 hit")
	check(v3.current_state == CharacterVisual.State.IDLE, "P3 unaffected by P2 hit")
	check(v4.current_state == CharacterVisual.State.IDLE, "P4 unaffected by P2 hit")
	v2._process_player(0.22)

	# P3 is downed and revived -> P1, P2, P4 unaffected
	p3.health.take_damage(DamageEvent.new(1000))
	v1._process_player(0.016)
	v2._process_player(0.016)
	v3._process_player(0.016)
	v4._process_player(0.016)
	check(v3.current_state == CharacterVisual.State.DOWNED, "P3 is DOWNED")
	check(v1.current_state == CharacterVisual.State.IDLE, "P1 unaffected by P3 death")
	check(v2.current_state == CharacterVisual.State.IDLE, "P2 unaffected by P3 death")
	check(v4.current_state == CharacterVisual.State.IDLE, "P4 unaffected by P3 death")

	p3.health.revive(50.0)
	v3._process_player(0.016)
	check(v3.current_state == CharacterVisual.State.REVIVE, "P3 is REVIVING")
	check(v1.current_state == CharacterVisual.State.IDLE, "P1 unaffected by P3 revive")
	v3._process_player(0.40)
	check(v3.current_state == CharacterVisual.State.IDLE, "P3 settles in IDLE")

	# Team color identity distinct across all 4 players
	var tints: Array[Color] = [p1.identity.tint, p2.identity.tint, p3.identity.tint, p4.identity.tint]
	check(tints[0] != tints[1], "P1 and P2 have distinct tints")
	check(tints[1] != tints[2], "P2 and P3 have distinct tints")
	check(tints[2] != tints[3], "P3 and P4 have distinct tints")

	# =========================================================================
	# 6. COLLISION AND WEAPON RACK INDEPENDENCE
	# =========================================================================
	var shape1: CircleShape2D = (p1.get_node("CollisionShape2D") as CollisionShape2D).shape as CircleShape2D
	check(shape1 != null and shape1.radius == 16.0, "P1 collision radius is exactly 16.0")
	check((p1.get_node("CollisionShape2D") as Node2D).position == Vector2.ZERO, "collision shape origin remains at (0, 0)")
	check((p1.get_node("WeaponRack") as Node2D).position == Vector2.ZERO, "WeaponRack origin remains at (0, 0)")
	check(p1.speed == 220.0, "player gameplay speed remains 220.0")
	check(p1.dash.burst_speed == 680.0, "dash burst speed remains 680.0")

	# =========================================================================
	# 6b. VISUAL ROOT VS GAMEPLAY ROOT SEPARATION (DEFORMATION ISOLATION)
	# =========================================================================
	var p_pos_before: Vector2 = p1.global_position
	var col_pos_before: Vector2 = (p1.get_node("CollisionShape2D") as Node2D).global_position
	var rack_pos_before: Vector2 = (p1.get_node("WeaponRack") as Node2D).global_position

	# Heavily deform the visual pivot (squash, stretch, rotate, translate)
	v1._pivot.scale = Vector2(3.5, 0.25)
	v1._pivot.rotation = 1.45
	v1._pivot.position = Vector2(25.0, -40.0)

	# Verify gameplay collision and weapon origins are completely untouched by visual deformation
	check(p1.global_position == p_pos_before, "player gameplay position untouched by visual deformation")
	check((p1.get_node("CollisionShape2D") as Node2D).global_position == col_pos_before, "collision global position untouched by visual deformation")
	check((p1.get_node("WeaponRack") as Node2D).global_position == rack_pos_before, "WeaponRack global position untouched by visual deformation")
	check(shape1.radius == 16.0, "collision shape radius untouched by visual deformation")

	# Reset visual pivot
	v1._pivot.scale = Vector2.ONE
	v1._pivot.rotation = 0.0
	v1._pivot.position = Vector2.ZERO

	# =========================================================================
	# 7. REPEATED CYCLES AND NODE LEAK PREVENTION
	# =========================================================================
	var node_count_before: int = v1.get_child_count() + v1._pivot.get_child_count()
	for cycle in range(10):
		# Die
		p1.health.died.emit(DamageEvent.new(1000))
		v1._process_player(0.016)
		# Revive
		p1.health.revive(100.0)
		v1._process_player(0.40)
		# Dash
		p1.dash.remaining = 0.16
		v1._process_player(0.016)
		p1.dash.remaining = 0.0
		v1._process_player(0.016)
		# Hit
		p1.health.take_damage(DamageEvent.new(10))
		v1._process_player(0.20)

	var node_count_after: int = v1.get_child_count() + v1._pivot.get_child_count()
	check(node_count_before == node_count_after, "10 full state cycles did not leak any nodes")

	arena.free()

	print("--- CHARACTER PRESENTATION SEAM TESTS FINISHED ---")
	print("RESULT: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
