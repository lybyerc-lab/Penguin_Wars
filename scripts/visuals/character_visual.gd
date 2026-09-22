class_name CharacterVisual
extends Node2D
## Production player penguin presentation matching the approved Concept C (Broad 2.5D) sheet.
## Cosmetic-only animation and team colors, strictly independent from movement/health rules.

enum State {
	IDLE,
	WADDLE,
	DASH,
	HIT,
	DOWNED,
	REVIVE,
}

@export var enemy: bool = false

var current_state: State = State.IDLE

var _time: float = 0.0
var _waddle_time: float = 0.0
var _hit_timer: float = 0.0
var _revive_timer: float = 0.0
var _halo_angle: float = 0.0
var _facing_direction: float = 1.0

# Actor / Controller references
var _actor: CharacterBody2D
var _health: Health
var _dash: DashController

# Legacy enemy sprite
var _enemy_body: Sprite2D

# Modular Penguin Puppet Nodes (Player)
var _pivot: Node2D
var _rear_flipper: Sprite2D
var _rear_foot: Sprite2D
var _torso: Sprite2D
var _belly: Sprite2D
var _head: Sprite2D
var _eyes: Sprite2D
var _beak: Sprite2D
var _scarf_wrap: Sprite2D
var _scarf_tail: Sprite2D
var _front_foot: Sprite2D
var _front_flipper: Sprite2D

# Downed orbital halo
var _halo: Node2D
var _halo_fish_1: Sprite2D
var _halo_fish_2: Sprite2D
var _halo_star_1: Sprite2D
var _halo_star_2: Sprite2D
var _halo_star_3: Sprite2D
var _halo_star_4: Sprite2D

# Preloaded Textures
const TEX_TORSO = preload("res://assets/characters/playable_v1/torso.svg")
const TEX_BELLY = preload("res://assets/characters/playable_v1/belly.svg")
const TEX_HEAD = preload("res://assets/characters/playable_v1/head.svg")
const TEX_BEAK = preload("res://assets/characters/playable_v1/beak.svg")
const TEX_BEAK_OPEN = preload("res://assets/characters/playable_v1/beak_open.svg")
const TEX_EYES_ALERT = preload("res://assets/characters/playable_v1/eyes_alert.svg")
const TEX_EYES_HIT = preload("res://assets/characters/playable_v1/eyes_hit.svg")
const TEX_EYES_WOOZY = preload("res://assets/characters/playable_v1/eyes_woozy.svg")
const TEX_FLIPPER_FRONT = preload("res://assets/characters/playable_v1/flipper_front.svg")
const TEX_FLIPPER_REAR = preload("res://assets/characters/playable_v1/flipper_rear.svg")
const TEX_FOOT = preload("res://assets/characters/playable_v1/foot.svg")
const TEX_SCARF_WRAP = preload("res://assets/characters/playable_v1/scarf_wrap.svg")
const TEX_SCARF_TAIL = preload("res://assets/characters/playable_v1/scarf_tail.svg")
const TEX_KO_FISH = preload("res://assets/characters/playable_v1/ko_fish.svg")
const TEX_KO_STAR = preload("res://assets/characters/playable_v1/ko_star.svg")
const TEX_SEAL = preload("res://assets/characters/seal_raider.svg")

const HIT_DURATION: float = 0.18
const REVIVE_DURATION: float = 0.35
const PUPPET_BASE_SCALE: float = 0.48

func _ready() -> void:
	_actor = get_parent() as CharacterBody2D
	if enemy:
		_setup_enemy()
	else:
		_setup_player()

func _setup_enemy() -> void:
	_enemy_body = Sprite2D.new()
	_enemy_body.texture = TEX_SEAL
	_enemy_body.scale = Vector2.ONE * 0.55
	_enemy_body.position.y = -9
	add_child(_enemy_body)

func _setup_player() -> void:
	_health = _actor.get_node_or_null("Health") as Health if _actor != null else null
	_dash = _actor.get_node_or_null("Dash") as DashController if _actor != null else null

	if _health != null:
		if not _health.damaged.is_connected(_on_damaged):
			_health.damaged.connect(_on_damaged)
		if not _health.died.is_connected(_on_died):
			_health.died.connect(_on_died)
		if not _health.revived.is_connected(_on_revived):
			_health.revived.connect(_on_revived)

	_pivot = Node2D.new()
	_pivot.scale = Vector2.ONE * PUPPET_BASE_SCALE
	add_child(_pivot)

	_rear_flipper = Sprite2D.new()
	_rear_flipper.texture = TEX_FLIPPER_REAR
	_rear_flipper.offset = Vector2(0, 16)
	_rear_flipper.z_index = -2
	_pivot.add_child(_rear_flipper)

	_rear_foot = Sprite2D.new()
	_rear_foot.texture = TEX_FOOT
	_rear_foot.offset = Vector2(0, 6)
	_rear_foot.z_index = 8
	_pivot.add_child(_rear_foot)

	_torso = Sprite2D.new()
	_torso.texture = TEX_TORSO
	_torso.z_index = 0
	_pivot.add_child(_torso)

	_belly = Sprite2D.new()
	_belly.texture = TEX_BELLY
	_belly.z_index = 1
	_pivot.add_child(_belly)

	_head = Sprite2D.new()
	_head.texture = TEX_HEAD
	_head.z_index = 2
	_pivot.add_child(_head)

	_eyes = Sprite2D.new()
	_eyes.texture = TEX_EYES_ALERT
	_eyes.z_index = 3
	_pivot.add_child(_eyes)

	_beak = Sprite2D.new()
	_beak.texture = TEX_BEAK
	_beak.z_index = 4
	_pivot.add_child(_beak)

	_scarf_wrap = Sprite2D.new()
	_scarf_wrap.texture = TEX_SCARF_WRAP
	_scarf_wrap.z_index = 5
	_pivot.add_child(_scarf_wrap)

	_scarf_tail = Sprite2D.new()
	_scarf_tail.texture = TEX_SCARF_TAIL
	_scarf_tail.offset = Vector2(-16, 0)
	_scarf_tail.z_index = 6
	_pivot.add_child(_scarf_tail)

	_front_flipper = Sprite2D.new()
	_front_flipper.texture = TEX_FLIPPER_FRONT
	_front_flipper.offset = Vector2(0, 16)
	_front_flipper.z_index = 7
	_pivot.add_child(_front_flipper)

	_front_foot = Sprite2D.new()
	_front_foot.texture = TEX_FOOT
	_front_foot.offset = Vector2(0, 6)
	_front_foot.z_index = 8
	_pivot.add_child(_front_foot)

	_setup_halo()
	_update_team_tint()
	_apply_pose_idle(0.0)

func _setup_halo() -> void:
	_halo = Node2D.new()
	_halo.position = Vector2(0, -32)
	_halo.z_index = 10
	_halo.visible = false
	add_child(_halo)

	_halo_fish_1 = Sprite2D.new()
	_halo_fish_1.texture = TEX_KO_FISH
	_halo_fish_1.scale = Vector2.ONE * 0.72
	_halo.add_child(_halo_fish_1)

	_halo_fish_2 = Sprite2D.new()
	_halo_fish_2.texture = TEX_KO_FISH
	_halo_fish_2.scale = Vector2.ONE * 0.72
	_halo.add_child(_halo_fish_2)

	_halo_star_1 = Sprite2D.new()
	_halo_star_1.texture = TEX_KO_STAR
	_halo_star_1.scale = Vector2.ONE * 0.65
	_halo.add_child(_halo_star_1)

	_halo_star_2 = Sprite2D.new()
	_halo_star_2.texture = TEX_KO_STAR
	_halo_star_2.scale = Vector2.ONE * 0.65
	_halo.add_child(_halo_star_2)

	_halo_star_3 = Sprite2D.new()
	_halo_star_3.texture = TEX_KO_STAR
	_halo_star_3.scale = Vector2.ONE * 0.65
	_halo.add_child(_halo_star_3)

	_halo_star_4 = Sprite2D.new()
	_halo_star_4.texture = TEX_KO_STAR
	_halo_star_4.scale = Vector2.ONE * 0.65
	_halo.add_child(_halo_star_4)

func _update_team_tint() -> void:
	var tint: Color = Color("38bdf8")
	if _actor is PenguinPlayer:
		var p := _actor as PenguinPlayer
		if p.identity != null:
			tint = p.identity.tint
	_scarf_wrap.modulate = tint
	_scarf_tail.modulate = tint

func _on_damaged(_event: DamageEvent) -> void:
	if enemy:
		return
	if _health != null and not _health.is_alive():
		return
	_hit_timer = HIT_DURATION

func _on_died(_event: DamageEvent) -> void:
	if enemy:
		return
	_hit_timer = 0.0
	_revive_timer = 0.0
	current_state = State.DOWNED

func _on_revived(_current: float) -> void:
	if enemy:
		return
	_hit_timer = 0.0
	_revive_timer = REVIVE_DURATION
	current_state = State.REVIVE

func _process(delta: float) -> void:
	_time += delta
	if enemy:
		_process_enemy(delta)
	else:
		_process_player(delta)
	queue_redraw()

func _process_enemy(_delta: float) -> void:
	if _actor == null or _enemy_body == null:
		return
	var moving: bool = _actor.velocity.length_squared() > 20.0
	var alive: bool = true
	var health_node := _actor.get_node_or_null("Health") as Health
	if health_node != null:
		alive = health_node.is_alive()
	var bob: float = sin(_time * 13.0) * 2.2 if moving and alive else sin(_time * 2.5) * 0.7
	_enemy_body.position.y = -9 + bob
	_enemy_body.rotation = sin(_time * 13.0) * 0.06 if moving and alive else 0.0
	_enemy_body.modulate = Color.WHITE if alive else Color("758794")
	if not alive:
		_enemy_body.rotation = PI * 0.5

func _process_player(delta: float) -> void:
	if _pivot == null:
		return

	if _hit_timer > 0.0:
		_hit_timer = maxf(0.0, _hit_timer - delta)
	if _revive_timer > 0.0:
		_revive_timer = maxf(0.0, _revive_timer - delta)

	var alive: bool = _health.is_alive() if _health != null else true
	var dashing: bool = _dash.is_active() if _dash != null else false
	var vel: Vector2 = _actor.velocity if _actor != null else Vector2.ZERO
	var moving: bool = vel.length_squared() > 10.0

	# Determine State Priority
	if not alive:
		current_state = State.DOWNED
	elif _revive_timer > 0.0:
		current_state = State.REVIVE
	elif _hit_timer > 0.0:
		current_state = State.HIT
	elif dashing:
		current_state = State.DASH
	elif moving:
		current_state = State.WADDLE
	else:
		current_state = State.IDLE

	# Update Facing Direction
	if current_state == State.DASH and _dash != null:
		if absf(_dash.direction.x) > 0.05:
			_facing_direction = 1.0 if _dash.direction.x > 0 else -1.0
	elif moving and current_state != State.DOWNED:
		if absf(vel.x) > 5.0:
			_facing_direction = 1.0 if vel.x > 0 else -1.0

	_pivot.scale = Vector2(_facing_direction * PUPPET_BASE_SCALE, PUPPET_BASE_SCALE)

	# Execute State Animation
	match current_state:
		State.IDLE:
			_apply_pose_idle(delta)
		State.WADDLE:
			_apply_pose_waddle(delta)
		State.DASH:
			_apply_pose_dash(delta)
		State.HIT:
			_apply_pose_hit(delta)
		State.DOWNED:
			_apply_pose_downed(delta)
		State.REVIVE:
			_apply_pose_revive(delta)

func _apply_pose_idle(_delta: float) -> void:
	_eyes.texture = TEX_EYES_ALERT
	_beak.texture = TEX_BEAK
	_halo.visible = false

	var breath: float = sin(_time * 2.8)
	_torso.position = Vector2(0, 14 + breath * 0.7)
	_torso.rotation = 0.0
	_torso.scale = Vector2(1.0 + breath * 0.015, 1.0 - breath * 0.015)
	_belly.position = _torso.position
	_belly.rotation = 0.0
	_belly.scale = _torso.scale

	_head.position = Vector2(0, -18 + breath * 0.9)
	_head.rotation = 0.0
	_head.scale = Vector2.ONE
	_eyes.position = _head.position
	_eyes.rotation = _head.rotation
	_eyes.scale = _head.scale
	_beak.position = _head.position
	_beak.rotation = _head.rotation
	_beak.scale = _head.scale

	_scarf_wrap.position = Vector2(2, 2 + breath * 0.8)
	_scarf_wrap.rotation = 0.0
	_scarf_tail.position = Vector2(-24, 2 + breath * 0.8)
	_scarf_tail.rotation = sin(_time * 2.8 - 0.4) * 0.06

	_front_flipper.position = Vector2(32, 14)
	_front_flipper.rotation = 0.12 + breath * 0.03
	_rear_flipper.position = Vector2(-26, 10)
	_rear_flipper.rotation = -0.06 - breath * 0.03

	_front_foot.position = Vector2(16, 42)
	_front_foot.rotation = 0.0
	_rear_foot.position = Vector2(-16, 40)
	_rear_foot.rotation = 0.0

func _apply_pose_waddle(delta: float) -> void:
	_eyes.texture = TEX_EYES_ALERT
	_beak.texture = TEX_BEAK
	_halo.visible = false

	_waddle_time += delta
	var w_phase: float = _waddle_time * 12.0
	var forward_lean: float = 0.18
	var sway: float = sin(w_phase) * 0.20
	var bounce: float = absf(sin(w_phase)) * 2.8

	_torso.position = Vector2(sway * 4.0, 14 - bounce)
	_torso.rotation = sway + forward_lean
	_torso.scale = Vector2.ONE
	_belly.position = _torso.position
	_belly.rotation = _torso.rotation
	_belly.scale = Vector2.ONE

	_head.position = Vector2(sway * 8.0, -18 - bounce)
	_head.rotation = sway * 0.8 + forward_lean
	_head.scale = Vector2.ONE
	_eyes.position = _head.position
	_eyes.rotation = _head.rotation
	_eyes.scale = _head.scale
	_beak.position = _head.position
	_beak.rotation = _head.rotation
	_beak.scale = _head.scale

	_scarf_wrap.position = Vector2(2 + sway * 5.0, 2 - bounce)
	_scarf_wrap.rotation = sway * 0.9 + forward_lean
	_scarf_tail.position = Vector2(-24, 2 - bounce)
	_scarf_tail.rotation = sin(w_phase - 0.8) * 0.35 - 0.15

	# Alternating foot stepping with visible weight transfer and clear daylight lift
	var r_step: float = maxf(0.0, sin(w_phase)) * 9.0
	var l_step: float = maxf(0.0, -sin(w_phase)) * 9.0
	_front_foot.position = Vector2(16, 42 - r_step)
	_front_foot.rotation = -r_step * 0.04
	_rear_foot.position = Vector2(-16, 40 - l_step)
	_rear_foot.rotation = l_step * 0.04

	# Counter-balancing flippers
	_front_flipper.position = Vector2(32, 14 - bounce)
	_front_flipper.rotation = -sin(w_phase) * 0.65 + 0.15
	_rear_flipper.position = Vector2(-26, 10 - bounce)
	_rear_flipper.rotation = sin(w_phase) * 0.60 - 0.15

func _apply_pose_dash(_delta: float) -> void:
	_eyes.texture = TEX_EYES_ALERT
	_beak.texture = TEX_BEAK
	_halo.visible = false

	var lean: float = 0.58
	_torso.position = Vector2(10, 14)
	_torso.rotation = lean
	_torso.scale = Vector2(1.08, 0.94)
	_belly.position = _torso.position
	_belly.rotation = lean
	_belly.scale = _torso.scale

	_head.position = Vector2(16, -16)
	_head.rotation = lean * 0.95
	_head.scale = Vector2.ONE
	_eyes.position = _head.position
	_eyes.rotation = _head.rotation
	_eyes.scale = _head.scale
	_beak.position = _head.position
	_beak.rotation = _head.rotation
	_beak.scale = _head.scale

	_scarf_wrap.position = Vector2(12, 0)
	_scarf_wrap.rotation = lean
	_scarf_tail.position = Vector2(-22, 0)
	_scarf_tail.rotation = -1.15 + sin(_time * 28.0) * 0.12

	_front_flipper.position = Vector2(20, 12)
	_front_flipper.rotation = -1.15
	_rear_flipper.position = Vector2(-22, 10)
	_rear_flipper.rotation = -1.05

	_front_foot.position = Vector2(10, 36)
	_front_foot.rotation = 0.40
	_rear_foot.position = Vector2(-14, 34)
	_rear_foot.rotation = 0.35

func _apply_pose_hit(_delta: float) -> void:
	_eyes.texture = TEX_EYES_HIT
	_beak.texture = TEX_BEAK_OPEN
	_halo.visible = false

	var p: float = _hit_timer / HIT_DURATION
	var recoil_rot: float = -0.38 * p
	var recoil_y: float = -8.5 * sin(p * PI)

	_torso.position = Vector2(-6 * p, 14 + recoil_y)
	_torso.rotation = recoil_rot
	_torso.scale = Vector2(0.92, 1.08)
	_belly.position = _torso.position
	_belly.rotation = recoil_rot
	_belly.scale = _torso.scale

	_head.position = Vector2(-4 * p, -18 + recoil_y)
	_head.rotation = recoil_rot * 1.15
	_head.scale = Vector2.ONE
	_eyes.position = _head.position
	_eyes.rotation = _head.rotation
	_eyes.scale = _head.scale
	_beak.position = _head.position
	_beak.rotation = _head.rotation
	_beak.scale = _head.scale

	_scarf_wrap.position = Vector2(2 - 2 * p, 2 + recoil_y)
	_scarf_wrap.rotation = recoil_rot
	_scarf_tail.position = Vector2(-24 - 4 * p, 2 + recoil_y)
	_scarf_tail.rotation = 0.50 * p

	_front_flipper.position = Vector2(32, 14 + recoil_y)
	_front_flipper.rotation = 0.95 * p
	_rear_flipper.position = Vector2(-26, 10 + recoil_y)
	_rear_flipper.rotation = -0.85 * p

	_front_foot.position = Vector2(16, 42 - 7.0 * sin(p * PI))
	_front_foot.rotation = -0.35 * p
	_rear_foot.position = Vector2(-16, 40)
	_rear_foot.rotation = 0.15 * p

func _apply_pose_downed(delta: float) -> void:
	_eyes.texture = TEX_EYES_WOOZY
	_beak.texture = TEX_BEAK
	_halo.visible = true

	var d_breath: float = sin(_time * 2.2) * 0.75

	_torso.position = Vector2(0, 24 + d_breath)
	_torso.rotation = 0.0
	_torso.scale = Vector2(1.28, 0.52)
	_belly.position = _torso.position
	_belly.rotation = 0.0
	_belly.scale = _torso.scale

	_head.position = Vector2(22, 22 + d_breath)
	_head.rotation = 0.08
	_head.scale = Vector2(1.15, 0.60)
	_eyes.position = _head.position
	_eyes.rotation = _head.rotation
	_eyes.scale = _head.scale
	_beak.position = _head.position
	_beak.rotation = _head.rotation
	_beak.scale = _head.scale

	_scarf_wrap.position = Vector2(16, 22 + d_breath)
	_scarf_wrap.rotation = 0.0
	_scarf_tail.position = Vector2(4, 24 + d_breath)
	_scarf_tail.rotation = 1.42

	_front_flipper.position = Vector2(36, 26)
	_front_flipper.rotation = 1.45
	_rear_flipper.position = Vector2(-30, 24)
	_rear_flipper.rotation = -1.45

	_front_foot.position = Vector2(-20, 26)
	_front_foot.rotation = 0.60
	_rear_foot.position = Vector2(-32, 24)
	_rear_foot.rotation = -0.40

	# Halo orbital loop (2 fish and 4 stars in elliptical path above head)
	_halo_angle += delta * 3.2
	_halo.position = Vector2(_facing_direction * 10.0, -14.0)
	var rx: float = 24.0
	var ry: float = 8.0

	# 2 Fish at opposite angles
	_halo_fish_1.position = Vector2(cos(_halo_angle) * rx, sin(_halo_angle) * ry)
	_halo_fish_2.position = Vector2(cos(_halo_angle + PI) * rx, sin(_halo_angle + PI) * ry)
	_halo_fish_1.rotation = sin(_time * 5.0) * 0.15
	_halo_fish_2.rotation = sin(_time * 5.0 + PI) * 0.15

	# 4 Stars evenly spaced in the orbit
	_halo_star_1.position = Vector2(cos(_halo_angle + PI * 0.25) * rx, sin(_halo_angle + PI * 0.25) * ry)
	_halo_star_2.position = Vector2(cos(_halo_angle + PI * 0.75) * rx, sin(_halo_angle + PI * 0.75) * ry)
	_halo_star_3.position = Vector2(cos(_halo_angle + PI * 1.25) * rx, sin(_halo_angle + PI * 1.25) * ry)
	_halo_star_4.position = Vector2(cos(_halo_angle + PI * 1.75) * rx, sin(_halo_angle + PI * 1.75) * ry)
	_halo_star_1.rotation = _time * 4.0
	_halo_star_2.rotation = _time * 4.0 + 1.0
	_halo_star_3.rotation = _time * 4.0 + 2.0
	_halo_star_4.rotation = _time * 4.0 + 3.0

func _apply_pose_revive(_delta: float) -> void:
	_eyes.texture = TEX_EYES_ALERT
	_beak.texture = TEX_BEAK
	_halo.visible = false

	var progress: float = 1.0 - (_revive_timer / REVIVE_DURATION)

	# Smooth push up from ice: chest raises, flippers press down, feet tuck in
	var push_t: float = clampf(progress / 0.65, 0.0, 1.0)
	var tuck_t: float = clampf((progress - 0.4) / 0.6, 0.0, 1.0)

	var y_pos: float = lerpf(24.0, 14.0, push_t)
	var sx: float = lerpf(1.28, 1.0, push_t)
	var sy: float = lerpf(0.52, 1.0, push_t)

	_torso.position = Vector2(0.0, y_pos)
	_torso.rotation = lerpf(0.0, -0.15, push_t) * (1.0 - tuck_t)
	_torso.scale = Vector2(sx, sy)
	_belly.position = _torso.position
	_belly.rotation = _torso.rotation
	_belly.scale = _torso.scale

	_head.position = Vector2(lerpf(22.0, 0.0, push_t), lerpf(22.0, -18.0, push_t))
	_head.rotation = lerpf(0.08, 0.0, push_t)
	_head.scale = Vector2(lerpf(1.15, 1.0, push_t), lerpf(0.60, 1.0, push_t))
	_eyes.position = _head.position
	_eyes.rotation = _head.rotation
	_eyes.scale = _head.scale
	_beak.position = _head.position
	_beak.rotation = _head.rotation
	_beak.scale = _head.scale

	_scarf_wrap.position = Vector2(lerpf(16.0, 2.0, push_t), lerpf(22.0, 2.0, push_t))
	_scarf_wrap.rotation = 0.0
	_scarf_tail.position = Vector2(lerpf(4.0, -24.0, push_t), lerpf(24.0, 2.0, push_t))
	_scarf_tail.rotation = lerpf(1.42, 0.0, tuck_t)

	# Flippers pushing down against ice, then returning to sides
	_front_flipper.position = Vector2(lerpf(36.0, 32.0, push_t), lerpf(26.0, 14.0, push_t))
	_front_flipper.rotation = lerpf(1.45, 0.06, tuck_t)
	_rear_flipper.position = Vector2(lerpf(-30.0, -26.0, push_t), lerpf(24.0, 10.0, push_t))
	_rear_flipper.rotation = lerpf(-1.45, -0.06, tuck_t)

	# Feet tucking back underneath
	_front_foot.position = Vector2(lerpf(-20.0, 16.0, tuck_t), lerpf(26.0, 42.0, tuck_t))
	_front_foot.rotation = lerpf(0.60, 0.0, tuck_t)
	_rear_foot.position = Vector2(lerpf(-32.0, -16.0, tuck_t), lerpf(24.0, 40.0, tuck_t))
	_rear_foot.rotation = lerpf(-0.40, 0.0, tuck_t)

func _draw() -> void:
	if enemy:
		draw_set_transform(Vector2(0, 13), 0, Vector2(1, 0.35))
		draw_circle(Vector2.ZERO, 24, Color(0.02, 0.12, 0.2, 0.24))
		draw_set_transform(Vector2.ZERO)
		return

	# Soft ground shadow dynamically shaped by character state
	var sy: float = 22.0
	var sx: float = 34.0
	var s_scale_y: float = 11.0
	var alpha: float = 0.38

	match current_state:
		State.DASH:
			sy = 18.0
			sx = 38.0
			s_scale_y = 9.0
			alpha = 0.42
		State.DOWNED:
			sy = 16.0
			sx = 44.0
			s_scale_y = 14.0
			alpha = 0.44
		State.HIT:
			sy = 22.0
			sx = 28.0
			s_scale_y = 10.0
			alpha = 0.32
		State.REVIVE:
			var t: float = 1.0 - (_revive_timer / REVIVE_DURATION)
			sy = lerpf(16.0, 22.0, t)
			sx = lerpf(44.0, 34.0, t)
			s_scale_y = lerpf(14.0, 11.0, t)
			alpha = lerpf(0.44, 0.38, t)

	draw_set_transform(Vector2(0, sy), 0, Vector2(sx / 20.0, s_scale_y / 20.0))
	draw_circle(Vector2.ZERO, 20.0, Color(0.02, 0.08, 0.16, alpha))
	draw_set_transform(Vector2.ZERO)
