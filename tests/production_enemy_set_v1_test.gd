extends SceneTree
## Production Enemy Set V1 is presentation-only. This test locks the supplied
## frame/anchor/shadow/state contract and the unchanged gameplay values.

const ROLLY: PackedScene = preload("res://scenes/actors/rolly.tscn")
const SKUA: PackedScene = preload("res://scenes/actors/skua_slinger.tscn")
const TUSKBULL: PackedScene = preload("res://scenes/actors/tuskbull.tscn")
const FALLBACK: PackedScene = preload("res://scenes/actors/enemy.tscn")
const ARENA: PackedScene = preload("res://scenes/arena/test_arena.tscn")
const MANIFEST_PATH := "res://assets/characters/enemies/production_enemy_set_v1_manifest.json"
const MANIFEST_SHA256 := "dd4c02fb274d875677dee68c237c5a4ec4cd33bed310c48f71a64dd104b30cb4"

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _spawn(scene: PackedScene, host: Node) -> ArenaEnemy:
	var enemy := scene.instantiate() as ArenaEnemy
	host.add_child(enemy)
	await process_frame
	enemy.set_physics_process(false)
	return enemy

func _run() -> void:
	check(FileAccess.get_sha256(MANIFEST_PATH) == MANIFEST_SHA256, "runtime manifest is the byte-identical numerical authority")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	check(manifest.get("frame_rate", 0) == 24, "manifest locks all enemy clips to 24 fps")
	var expected := {
		"rolly": {
			"canvas": Vector2(96, 96),
			"clips": {"idle": [16, true], "move": [12, true], "hit": [5, false], "defeat": [8, false]},
		},
		"skua_slinger": {
			"canvas": Vector2(176, 144),
			"clips": {"idle": [16, true], "move": [12, true], "windup": [19, false], "throw": [8, false], "hit": [5, false], "defeat": [8, false]},
		},
		"tuskbull": {
			"canvas": Vector2(320, 200),
			"clips": {"idle": [16, true], "move": [16, true], "windup": [20, false], "charge": [8, true], "crash": [6, false], "stunned": [12, true], "recover": [10, false], "hit": [5, false], "defeat": [10, false]},
		},
	}
	var total_frames: int = 0
	for enemy_id: String in expected:
		var frames := load("res://resources/characters/enemies/%s_frames.tres" % enemy_id) as SpriteFrames
		check(frames != null, "%s SpriteFrames resource loads" % enemy_id)
		if frames == null:
			continue
		var clips: Dictionary = expected[enemy_id]["clips"]
		for clip_id: String in clips:
			var contract: Array = clips[clip_id]
			var count: int = contract[0]
			total_frames += count
			check(frames.has_animation(clip_id), "%s has %s" % [enemy_id, clip_id])
			check(frames.get_frame_count(clip_id) == count, "%s/%s has the manifest frame count" % [enemy_id, clip_id])
			check(is_equal_approx(frames.get_animation_speed(clip_id), 24.0), "%s/%s runs at 24 fps" % [enemy_id, clip_id])
			check(frames.get_animation_loop(clip_id) == bool(contract[1]), "%s/%s uses the manifest loop flag" % [enemy_id, clip_id])
			var first_texture := frames.get_frame_texture(clip_id, 0)
			check(first_texture != null and first_texture.get_size() == expected[enemy_id]["canvas"], "%s/%s preserves the locked canvas" % [enemy_id, clip_id])
			for frame_index: int in range(count):
				var path := "res://assets/characters/enemies/%s/production/%s/%s_%s_%03d.png" % [enemy_id, clip_id, enemy_id, clip_id, frame_index]
				check(FileAccess.file_exists(path), "%s frame %03d exists" % [clip_id, frame_index])
				var import_text := FileAccess.get_file_as_string(path + ".import")
				check("compress/mode=0" in import_text and "mipmaps/generate=false" in import_text, "%s uses lossless no-mipmap import" % path)
	check(total_frames == 212, "all 212 supplied runtime frames are represented")

	var host := Node2D.new()
	root.add_child(host)
	set_meta(CharacterVisual.ACTOR_SUN_META, CharacterVisual.DEFAULT_ACTOR_SUN)
	var rolly: ArenaEnemy = await _spawn(ROLLY, host)
	var skua: ArenaEnemy = await _spawn(SKUA, host)
	var tuskbull: ArenaEnemy = await _spawn(TUSKBULL, host)
	var fallback: ArenaEnemy = await _spawn(FALLBACK, host)
	var rolly_visual := rolly.get_node("CharacterVisual") as CharacterVisual
	var skua_visual := skua.get_node("CharacterVisual") as CharacterVisual
	var tuskbull_visual := tuskbull.get_node("CharacterVisual") as CharacterVisual
	var fallback_visual := fallback.get_node("CharacterVisual") as CharacterVisual

	check(rolly_visual.enemy_art_id == &"rolly" and skua_visual.enemy_art_id == &"skua_slinger" and tuskbull_visual.enemy_art_id == &"tuskbull", "Phase A scenes assign all three production art ids")
	check(rolly_visual._enemy_anim != null and skua_visual._enemy_anim != null and tuskbull_visual._enemy_anim != null, "production enemies use AnimatedSprite2D")
	check(rolly_visual._enemy_body == null and skua_visual._enemy_body == null and tuskbull_visual._enemy_body == null, "production enemies no longer instantiate the seal placeholder")
	check(fallback_visual._enemy_body != null and fallback_visual._enemy_anim == null and fallback_visual.enemy_art_id.is_empty(), "unrelated enemies retain the fallback seal path")

	check(rolly.speed == 96.0 and rolly.contact_damage == 5.0 and rolly.contact_radius == 25.0 and rolly.hit_radius == 14.0 and rolly.health.maximum == 16.0, "Rolly gameplay values are unchanged")
	check(skua.speed == 68.0 and skua.contact_damage == 6.0 and skua.projectile_damage == 10.0 and skua.contact_radius == 29.0 and skua.hit_radius == 18.0 and skua.health.maximum == 22.0, "Skua gameplay values are unchanged")
	check(tuskbull.speed == 54.0 and tuskbull.contact_damage == 18.0 and tuskbull.contact_radius == 52.0 and tuskbull.hit_radius == 34.0 and tuskbull.health.maximum == 92.0, "Tuskbull gameplay values are unchanged")
	check(is_equal_approx((rolly.get_node("CollisionShape2D") as CollisionShape2D).scale.x * 13.0, 9.88), "Rolly collision is unchanged")
	check(is_equal_approx((skua.get_node("CollisionShape2D") as CollisionShape2D).scale.x * 13.0, 13.0), "Skua collision is unchanged")
	check(is_equal_approx((tuskbull.get_node("CollisionShape2D") as CollisionShape2D).scale.x * 13.0, 19.5), "Tuskbull collision is unchanged")

	check(rolly_visual._enemy_anim.offset == Vector2(0, -34) and is_equal_approx(rolly_visual._enemy_anim.scale.x * rolly_visual.scale.x, 0.5), "Rolly uses its exact anchor and world scale")
	check(skua_visual._enemy_anim.offset == Vector2(0, -56) and is_equal_approx(skua_visual._enemy_anim.scale.x * skua_visual.scale.x, 0.5), "Skua uses its exact anchor and world scale")
	check(tuskbull_visual._enemy_anim.offset == Vector2(0, -80) and is_equal_approx(tuskbull_visual._enemy_anim.scale.x * tuskbull_visual.scale.x, 0.5), "Tuskbull uses its exact anchor and world scale")
	check(rolly_visual._enemy_anim.modulate.is_equal_approx(CharacterVisual.AMBIENT_TINT), "production enemy art uses the Actor Grounding ambient tint")

	rolly.velocity = Vector2(96, 0)
	rolly_visual._process_enemy(0.0)
	check(rolly_visual._enemy_anim.animation == &"move" and is_equal_approx(rolly_visual._enemy_anim.speed_scale, 1.0), "Rolly velocity drives move at the manifest reference speed")
	rolly.health.take_damage(DamageEvent.new(1.0))
	check(rolly_visual._enemy_anim.animation == &"hit", "Rolly non-lethal damage drives hit once")

	var skua_behavior := skua.behavior as SkuaSlingerBehavior
	skua_behavior.direction = Vector2.LEFT
	skua_behavior.state = RangedBehavior.State.WINDUP
	skua_behavior.remaining = 0.4
	skua_visual._enemy_previous_behavior_state = RangedBehavior.State.WINDUP
	skua_visual._process_enemy(0.0)
	check(skua_visual._enemy_anim.animation == &"windup" and skua_visual._enemy_anim.frame == 9, "Skua windup frame is driven by remaining/windup_time")
	check(skua_visual._enemy_anim.flip_h, "Skua windup faces the committed left release direction")
	check(skua_visual._enemy_anim.position == Vector2.ZERO, "flipping Skua never shifts its anchor")
	check((skua_visual._contact_shadow.scale * Vector2(128, 64)).is_equal_approx(Vector2(28.3 * 1.08, 9.8)), "Skua uses its exact local contact size plus the retained windup stretch")
	check(skua_visual._contact_shadow.position.is_equal_approx(Vector2(1.1, 0.0)), "Skua contact offset mirrors with facing")
	check(is_equal_approx(skua_visual._cast_shadow.scale.x * 256.0, 105.3) and is_equal_approx(skua_visual._cast_shadow.scale.y * 64.0, 21.7), "Skua uses exact Frozen Coast cast dimensions")
	skua_behavior.remaining = 0.02
	skua_visual._process_enemy(0.0)
	skua_behavior.state = RangedBehavior.State.RECOVER
	skua_behavior.remaining = skua_behavior.shot_cooldown
	skua_visual._process_enemy(0.0)
	check(skua_visual._enemy_anim.animation == &"throw", "completed Skua windup transitions to throw")
	skua_visual._enemy_one_shot = &""
	skua_behavior.state = RangedBehavior.State.WINDUP
	skua_behavior.remaining = 0.5
	skua_visual._enemy_previous_behavior_state = RangedBehavior.State.WINDUP
	skua_visual._process_enemy(0.0)
	skua.health.take_damage(DamageEvent.new(1.0, 0, Vector2(250, 0)))
	check(skua_behavior.state == RangedBehavior.State.RECOVER and skua_visual._enemy_anim.animation == &"hit", "heavy-hit Skua cancel reads as hit instead of throw")

	var charge := tuskbull.behavior as ChargeBehavior
	check(charge.windup_time == 0.85 and charge.charge_speed == 430.0 and charge.charge_time == 0.85 and charge.recovery_time == 1.25 and charge.crash_recovery_time == 1.75 and charge.soft_charge_speed_multiplier == 0.65, "Tuskbull ChargeBehavior gameplay values are unchanged")
	charge.direction = Vector2.RIGHT
	charge.state = ChargeBehavior.State.WINDUP
	charge.remaining = 0.425
	tuskbull_visual._enemy_previous_behavior_state = ChargeBehavior.State.WINDUP
	tuskbull_visual._process_enemy(0.0)
	check(tuskbull_visual._enemy_anim.animation == &"windup" and tuskbull_visual._enemy_anim.frame == 10, "Tuskbull windup is driven by existing remaining time")
	charge.state = ChargeBehavior.State.CHARGE
	charge.remaining = 0.5
	charge.set_soft_charge_active(true)
	tuskbull_visual._process_enemy(0.0)
	check(tuskbull_visual._enemy_anim.animation == &"charge" and is_equal_approx(tuskbull_visual._enemy_anim.speed_scale, 0.65), "soft drift slows only the charge animation presentation")
	charge.on_world_collision(false)
	tuskbull_visual._process_enemy(0.0)
	check(charge.state == ChargeBehavior.State.CHARGE and not tuskbull_visual._enemy_crash_path and tuskbull_visual._enemy_anim.animation == &"charge", "soft drift/no-stun terrain never plays a crash")
	charge.on_world_collision(true)
	tuskbull_visual._process_enemy(0.0)
	var recoil_world: Vector2 = tuskbull_visual.to_global(tuskbull_visual._enemy_anim.position) - tuskbull_visual.global_position
	check(charge.state == ChargeBehavior.State.RECOVER and tuskbull_visual._enemy_anim.animation == &"crash", "hard impact starts the production crash clip")
	check(recoil_world.is_equal_approx(Vector2(-26.0, 0.0)), "hard impact recoils art exactly 26 world px opposite charge")
	check(tuskbull_visual._ground_shadow.position == tuskbull_visual._enemy_anim.position, "crash recoil offsets art and grounding shadow together")
	charge.remaining = 1.0
	tuskbull_visual._process_enemy(0.0)
	check(tuskbull_visual._enemy_anim.animation == &"stunned" and (tuskbull_visual.to_global(tuskbull_visual._enemy_anim.position) - tuskbull_visual.global_position).is_equal_approx(Vector2(-26.0, 0.0)), "recoil holds through stunned")
	charge.remaining = 0.2
	tuskbull_visual._process_enemy(0.0)
	var easing_recoil: float = (tuskbull_visual.to_global(tuskbull_visual._enemy_anim.position) - tuskbull_visual.global_position).length()
	check(tuskbull_visual._enemy_anim.animation == &"recover" and easing_recoil > 0.0 and easing_recoil < 26.0, "recoil eases back during recover")
	charge.state = ChargeBehavior.State.APPROACH
	charge.remaining = 0.0
	tuskbull.velocity = Vector2.ZERO
	tuskbull_visual._process_enemy(0.25)
	check(tuskbull_visual._enemy_anim.animation == &"idle" and tuskbull_visual._enemy_anim.position == Vector2.ZERO and tuskbull_visual._ground_shadow.position == Vector2.ZERO, "Tuskbull returns to anchored idle after recover")
	check((tuskbull_visual._contact_shadow.scale * Vector2(128, 64)).is_equal_approx(Vector2(64.5, 16.8)), "Tuskbull uses exact local contact dimensions")

	# Exercise the real Skua spawn seam: presentation starts at the mirrored art
	# release point while the authoritative landing position remains unchanged.
	var arena := ARENA.instantiate() as Node2D
	root.add_child(arena)
	await process_frame
	for node: Node in arena.find_children("*", "", true, false):
		if node is CharacterBody2D:
			node.set_physics_process(false)
	var projectile_skua := SKUA.instantiate() as ArenaEnemy
	projectile_skua.party = arena.party
	# Keep this presentation fixture outside every starter weapon's reach; the
	# test drives its throw directly and must not race autonomous player fire.
	projectile_skua.position = Vector2(450, 20)
	arena.get_node("Actors").add_child(projectile_skua)
	await process_frame
	projectile_skua.set_physics_process(false)
	var projectile_behavior := projectile_skua.behavior as SkuaSlingerBehavior
	projectile_behavior.state = RangedBehavior.State.WINDUP
	projectile_behavior.remaining = 0.0
	projectile_behavior.direction = Vector2.LEFT
	projectile_behavior.locked_target = Vector2(-120, 20)
	var authoritative_landing: Vector2 = projectile_behavior.locked_target
	projectile_behavior.movement(projectile_skua, arena.party.members()[0], 0.0)
	var eggs := get_nodes_in_group("enemy_projectiles")
	var egg := eggs.back() as SkuaIceEgg if not eggs.is_empty() else null
	check(egg != null and egg.release_offset == Vector2(-10, -24), "Skua egg receives the mirrored manifest release offset")
	if egg != null:
		egg.set_physics_process(false)
		var foot_origin: Vector2 = egg.global_position
		egg._physics_process(0.0)
		check(egg.global_position.is_equal_approx(foot_origin + Vector2(-10, -24)), "egg first draws at the art release point instead of the feet")
		check(egg.landing_position == authoritative_landing, "egg launch presentation does not change the authoritative landing point")

	arena.free()
	host.free()
	print("PRODUCTION ENEMY SET V1 TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
