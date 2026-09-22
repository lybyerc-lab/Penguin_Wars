class_name RunPickup
extends Node2D
## Pickup owns collection eligibility; the run decides where currency is credited.
signal collected(player_id: int, amount: int)

enum Kind { HEALTH, SNOWFLAKE }
enum ValueTier { SMALL, CHUNKY, BIG, JACKPOT }

const LANDING_DURATION: float = 0.22
const BASE_MAGNET_RADIUS: float = 30.0
const COLLECTION_RADIUS: float = 12.0
const COLLECTION_FX_DURATION: float = 0.14

@export var kind: Kind = Kind.HEALTH
@export var amount: int = 25
var party: PartyRoster
var claimed: bool = false
var shape_variant: int = 0

var _age: float = 0.0
var _is_magnetized: bool = false
var _target_player: PenguinPlayer = null
var _magnet_speed: float = 0.0
var _collecting: bool = false
var _collection_timer: float = 0.0

func _ready() -> void:
	shape_variant = abs(int(position.x * 7.0 + position.y * 13.0 + float(get_instance_id()))) % 3

func value_tier() -> ValueTier:
	if amount <= 2:
		return ValueTier.SMALL
	elif amount <= 5:
		return ValueTier.CHUNKY
	elif amount <= 9:
		return ValueTier.BIG
	else:
		return ValueTier.JACKPOT

func magnet_radius_for(player: PenguinPlayer) -> float:
	var bonus: float = 0.0
	if player != null and player.stats != null:
		bonus = player.stats.pickup_bonus
	return maxf(BASE_MAGNET_RADIUS, BASE_MAGNET_RADIUS + bonus)

func is_magnetized() -> bool:
	return _is_magnetized

func is_settled() -> bool:
	if kind == Kind.HEALTH:
		return true
	return _age >= LANDING_DURATION and not _is_magnetized and not _collecting

func collection_fx_active() -> bool:
	return _collecting

func _physics_process(delta: float) -> void:
	if _collecting:
		_collection_timer += delta
		queue_redraw()
		if _collection_timer >= COLLECTION_FX_DURATION:
			queue_free()
		return

	if claimed:
		return

	_age += delta
	queue_redraw()

	if party == null:
		return

	# HEALTH pickups preserve exact legacy collection behavior and timing
	if kind == Kind.HEALTH:
		if _age < 0.3:
			return
		var nearest_health: PenguinPlayer = null
		var best_health_dist: float = INF
		for player: PenguinPlayer in party.members(true):
			if player == null or not is_instance_valid(player) or not player.health.is_alive():
				continue
			if player.health.current >= player.health.maximum:
				continue
			var dist_sq: float = global_position.distance_squared_to(player.global_position)
			var reach: float = magnet_radius_for(player)
			if dist_sq <= reach * reach and dist_sq < best_health_dist:
				best_health_dist = dist_sq
				nearest_health = player
		if nearest_health != null:
			collect(nearest_health)
		return

	# SNOWFLAKE: Magnet suction toward nearest living eligible player
	# Find or validate target player
	if _target_player == null or not is_instance_valid(_target_player) or not _target_player.health.is_alive():
		_target_player = _find_nearest_living_player()
		_is_magnetized = (_target_player != null)
		if _is_magnetized and _magnet_speed <= 0.0:
			_magnet_speed = 220.0
	else:
		# Check if target player moved outside magnet range before movement began
		var dist_sq: float = global_position.distance_squared_to(_target_player.global_position)
		var reach: float = magnet_radius_for(_target_player)
		if not _is_magnetized and dist_sq > reach * reach:
			_target_player = null
			_is_magnetized = false

	# If magnetized, accelerate and pull toward player
	if _is_magnetized and _target_player != null:
		var target_pos: Vector2 = _target_player.global_position
		var dist: float = global_position.distance_to(target_pos)

		var tier: ValueTier = value_tier()
		var accel: float = 1400.0
		var max_speed: float = 750.0
		if tier == ValueTier.SMALL:
			accel = 1600.0
			max_speed = 850.0
		elif tier == ValueTier.JACKPOT:
			accel = 1100.0
			max_speed = 680.0

		_magnet_speed = minf(max_speed, _magnet_speed + accel * delta)
		var move_step: float = _magnet_speed * delta

		# If within reach distance or collection threshold, collect immediately
		if dist <= move_step or dist <= COLLECTION_RADIUS:
			collect(_target_player)
		else:
			global_position = global_position.move_toward(target_pos, move_step)

func _find_nearest_living_player() -> PenguinPlayer:
	var nearest: PenguinPlayer = null
	var min_dist_sq: float = INF
	for player: PenguinPlayer in party.members(true):
		if player == null or not is_instance_valid(player) or not player.health.is_alive():
			continue
		var dist_sq: float = global_position.distance_squared_to(player.global_position)
		var reach: float = magnet_radius_for(player)
		if dist_sq <= reach * reach and dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			nearest = player
	return nearest

func collect(player: PenguinPlayer) -> bool:
	if claimed or amount <= 0 or not player.health.is_alive():
		return false

	if kind == Kind.HEALTH:
		if player.health.current >= player.health.maximum:
			return false
		player.health.heal(amount)
		claimed = true
		collected.emit(player.identity.player_id, amount)
		queue_free()
		return true

	# SNOWFLAKE: Award value and signal immediately; play short visual finish
	claimed = true
	collected.emit(player.identity.player_id, amount)
	_collecting = true
	_collection_timer = 0.0
	_is_magnetized = false
	_target_player = null
	queue_redraw()
	return true

func _draw() -> void:
	if kind == Kind.HEALTH:
		var bob: float = sin(_age * 4.0) * 2.0
		draw_set_transform(Vector2(0, 7), 0, Vector2(1, 0.4))
		draw_circle(Vector2.ZERO, 12, Color(0, 0.1, 0.2, 0.2))
		draw_set_transform(Vector2(0, bob))
		draw_circle(Vector2.ZERO, 12, Color("275666"))
		draw_circle(Vector2.ZERO, 10, Color("81dda9"))
		draw_rect(Rect2(-2, -7, 4, 14), Color("effff1"))
		draw_rect(Rect2(-7, -2, 14, 4), Color("effff1"))
		draw_set_transform(Vector2.ZERO)
		return

	# SNOWFLAKE DRAWING
	var tier: ValueTier = value_tier()
	var base_radius: float = _tier_radius(tier)

	# 1. Collection finish effect (short expanding puff + scatter flecks)
	if _collecting:
		var p: float = clampf(_collection_timer / COLLECTION_FX_DURATION, 0.0, 1.0)
		var alpha: float = 1.0 - p
		# Expanding soft white/cyan puff
		var puff_radius: float = base_radius * (1.0 + p * 0.8)
		draw_circle(Vector2.ZERO, puff_radius, Color(0.9, 0.98, 1.0, 0.65 * alpha))
		draw_circle(Vector2.ZERO, puff_radius * 0.6, Color(1.0, 1.0, 1.0, 0.8 * alpha))
		# 4 procedural flecks scattering outward
		for i: int in range(4):
			var angle: float = i * (TAU / 4.0) + 0.35
			var fleck_dir: Vector2 = Vector2.from_angle(angle)
			var fleck_dist: float = base_radius * 0.8 + p * 24.0
			var fleck_pos: Vector2 = fleck_dir * fleck_dist
			draw_circle(fleck_pos, maxf(1.0, 2.5 * alpha), Color(0.95, 1.0, 1.0, 0.9 * alpha))
		# Central sparkle glint
		if p < 0.6:
			var glint_len: float = (1.0 - p / 0.6) * (base_radius * 0.9)
			draw_line(Vector2(-glint_len, 0), Vector2(glint_len, 0), Color.WHITE, 1.5)
			draw_line(Vector2(0, -glint_len), Vector2(0, glint_len), Color.WHITE, 1.5)
		return

	# 2. Normal Arrival / Landing / Idle animation state
	var visual_height: float = 0.0
	var scale_mult: Vector2 = Vector2.ONE
	var rot: float = 0.0

	if _age < LANDING_DURATION:
		var lp: float = _age / LANDING_DURATION
		if lp < 0.7:
			# Upward pop arc
			var arc: float = lp / 0.7
			var peak_h: float = 14.0
			if tier == ValueTier.BIG:
				peak_h = 17.0
			elif tier == ValueTier.JACKPOT:
				peak_h = 20.0
			visual_height = 4.0 * peak_h * arc * (1.0 - arc)
			scale_mult = Vector2(0.92, 1.08)
		elif lp < 0.85:
			# Landing impact squash
			var sp: float = (lp - 0.7) / 0.15
			var squash: float = sin(sp * PI)
			visual_height = 0.0
			scale_mult = Vector2(1.0 + squash * 0.28, 1.0 - squash * 0.24)
		else:
			# Tiny rebound
			var bp: float = (lp - 0.85) / 0.15
			visual_height = sin(bp * PI) * 2.2
			scale_mult = Vector2(0.98, 1.02)
	else:
		# Settled idle life on ice
		var idle_t: float = _age - LANDING_DURATION
		var wobble_spd: float = 2.4 if tier < ValueTier.BIG else 1.7
		rot = sin(idle_t * wobble_spd + float(shape_variant)) * 0.035
		var breath: float = sin(idle_t * wobble_spd * 1.5) * 0.015
		scale_mult = Vector2(1.0 + breath, 1.0 - breath)

	# Ground drop shadow: stays on the ice at y = +4
	var shadow_rx: float = base_radius * 1.15
	var shadow_ry: float = base_radius * 0.48
	var shadow_fade: float = clampf(1.0 - (visual_height / 35.0), 0.5, 1.0)
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(shadow_rx / 10.0 * shadow_fade, shadow_ry / 10.0 * shadow_fade))
	draw_circle(Vector2.ZERO, 10.0, Color(0.04, 0.08, 0.16, 0.32))

	# Chunky Snow Chunk body
	draw_set_transform(Vector2(0, -visual_height), rot, scale_mult)
	_draw_chunky_snow(tier, shape_variant, base_radius)
	draw_set_transform(Vector2.ZERO)

func _tier_radius(tier: ValueTier) -> float:
	match tier:
		ValueTier.SMALL:
			return 7.5
		ValueTier.CHUNKY:
			return 10.5
		ValueTier.BIG:
			return 14.0
		ValueTier.JACKPOT:
			return 18.5
	return 7.5

func _draw_chunky_snow(tier: ValueTier, variant: int, radius: float) -> void:
	match tier:
		ValueTier.SMALL:
			_draw_small_snow(variant, radius)
		ValueTier.CHUNKY:
			_draw_chunky_tier_snow(variant, radius)
		ValueTier.BIG:
			_draw_big_snow(variant, radius)
		ValueTier.JACKPOT:
			_draw_jackpot_snow(variant, radius)

func _draw_small_snow(variant: int, r: float) -> void:
	# Irregular rounded faceted snow clump
	var pts: PackedVector2Array
	match variant:
		0:
			pts = PackedVector2Array([
				Vector2(-r * 0.9, r * 0.2), Vector2(-r * 0.8, -r * 0.5), Vector2(-r * 0.25, -r * 0.9),
				Vector2(r * 0.55, -r * 0.75), Vector2(r * 0.95, -r * 0.15), Vector2(r * 0.7, r * 0.65),
				Vector2(-r * 0.3, r * 0.8)
			])
		1:
			pts = PackedVector2Array([
				Vector2(-r * 0.85, r * 0.4), Vector2(-r * 0.95, -r * 0.2), Vector2(-r * 0.4, -r * 0.85),
				Vector2(r * 0.3, -r * 0.9), Vector2(r * 0.9, -r * 0.3), Vector2(r * 0.8, r * 0.45),
				Vector2(0, r * 0.75)
			])
		_:
			pts = PackedVector2Array([
				Vector2(-r * 0.9, r * 0.5), Vector2(-r * 0.65, -r * 0.35), Vector2(-r * 0.15, -r * 0.9),
				Vector2(r * 0.65, -r * 0.6), Vector2(r * 0.85, r * 0.15), Vector2(r * 0.5, r * 0.7),
				Vector2(-r * 0.4, r * 0.75)
			])

	# Dark grounding silhouette rim
	draw_colored_polygon(pts, Color("284967"))
	# Underside slate-blue shadow layer
	var inner_shadow: PackedVector2Array = pts.duplicate()
	for i: int in range(inner_shadow.size()):
		inner_shadow[i] = inner_shadow[i] * 0.85 + Vector2(0, 0.5)
	draw_colored_polygon(inner_shadow, Color("4a7294"))

	# Crisp packed snow body (shifted slightly up toward light source)
	var body_pts: PackedVector2Array = pts.duplicate()
	for i: int in range(body_pts.size()):
		body_pts[i] = body_pts[i] * 0.72 + Vector2(-0.4, -0.9)
	draw_colored_polygon(body_pts, Color("dff2fc"))

	# Top highlight cap
	draw_circle(Vector2(-r * 0.25, -r * 0.45), r * 0.35, Color("ffffff"))

func _draw_chunky_tier_snow(variant: int, r: float) -> void:
	# Multi-lobed beefier snow clump with visible carved crevice
	var lobe1_pos: Vector2 = Vector2(-r * 0.25, -r * 0.1)
	var lobe1_r: float = r * 0.75
	var lobe2_pos: Vector2 = Vector2(r * 0.35, r * 0.15)
	var lobe2_r: float = r * 0.58
	if variant == 1:
		lobe1_pos = Vector2(-r * 0.2, r * 0.15)
		lobe2_pos = Vector2(r * 0.3, -r * 0.2)
	elif variant == 2:
		lobe1_pos = Vector2(r * 0.15, -r * 0.15)
		lobe2_pos = Vector2(-r * 0.35, r * 0.1)

	# Dark perimeter outlines
	draw_circle(lobe1_pos, lobe1_r + 1.2, Color("24425e"))
	draw_circle(lobe2_pos, lobe2_r + 1.2, Color("24425e"))

	# Underside shadow
	draw_circle(lobe1_pos + Vector2(0, 1.2), lobe1_r, Color("446e90"))
	draw_circle(lobe2_pos + Vector2(0, 1.0), lobe2_r, Color("446e90"))

	# Snow body
	draw_circle(lobe1_pos + Vector2(-0.5, -0.8), lobe1_r * 0.82, Color("dff2fc"))
	draw_circle(lobe2_pos + Vector2(-0.4, -0.6), lobe2_r * 0.82, Color("dff2fc"))

	# Crevice seam between lobes
	var seam_center: Vector2 = (lobe1_pos + lobe2_pos) * 0.5
	draw_line(seam_center - Vector2(0, r * 0.35), seam_center + Vector2(0, r * 0.45), Color("345878"), 1.8)

	# Pure white highlight crests
	draw_circle(lobe1_pos + Vector2(-lobe1_r * 0.25, -lobe1_r * 0.35), lobe1_r * 0.35, Color("ffffff"))
	draw_circle(lobe2_pos + Vector2(-lobe2_r * 0.2, -lobe2_r * 0.3), lobe2_r * 0.3, Color("ffffff"))

func _draw_big_snow(variant: int, r: float) -> void:
	# Heavy 3-lobed packed snowball lump with noticeable weight
	var c_base: Vector2 = Vector2(0, r * 0.2)
	var r_base: float = r * 0.72
	var c_left: Vector2 = Vector2(-r * 0.4, -r * 0.15)
	var r_left: float = r * 0.55
	var c_right: Vector2 = Vector2(r * 0.35, -r * 0.2)
	var r_right: float = r * 0.58

	if variant == 1:
		c_left = Vector2(-r * 0.35, -r * 0.25)
		c_right = Vector2(r * 0.4, 0)
	elif variant == 2:
		c_left = Vector2(-r * 0.4, 0.0)
		c_right = Vector2(r * 0.3, -r * 0.28)

	# Outer dark framing silhouette
	draw_circle(c_base, r_base + 1.4, Color("1e3852"))
	draw_circle(c_left, r_left + 1.4, Color("1e3852"))
	draw_circle(c_right, r_right + 1.4, Color("1e3852"))

	# Icy blue underside shading
	draw_circle(c_base + Vector2(0, 1.4), r_base, Color("3e6686"))
	draw_circle(c_left + Vector2(0, 1.1), r_left, Color("3e6686"))
	draw_circle(c_right + Vector2(0, 1.1), r_right, Color("3e6686"))

	# Crisp packed snow body
	draw_circle(c_base + Vector2(-0.5, -1.0), r_base * 0.82, Color("dff2fc"))
	draw_circle(c_left + Vector2(-0.5, -0.8), r_left * 0.82, Color("e6f5fe"))
	draw_circle(c_right + Vector2(-0.4, -0.8), r_right * 0.82, Color("e6f5fe"))

	# Crevice shadow relief
	draw_line(Vector2(-r * 0.1, -r * 0.3), Vector2(-r * 0.05, r * 0.2), Color("2e5270"), 1.8)
	draw_line(Vector2(r * 0.05, -r * 0.3), Vector2(r * 0.1, r * 0.15), Color("2e5270"), 1.8)

	# Highlights
	draw_circle(c_left + Vector2(-r_left * 0.2, -r_left * 0.35), r_left * 0.35, Color("ffffff"))
	draw_circle(c_right + Vector2(-r_right * 0.2, -r_right * 0.35), r_right * 0.35, Color("ffffff"))
	draw_circle(c_base + Vector2(0, -r_base * 0.2), r_base * 0.28, Color("ffffff"))

func _draw_jackpot_snow(variant: int, r: float) -> void:
	# Oversized glacial boulder chunk with crystalline facets and sparkling frost glints
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(-r * 0.95, r * 0.2), Vector2(-r * 0.85, -r * 0.5), Vector2(-r * 0.45, -r * 0.9),
		Vector2(r * 0.15, -r * 0.95), Vector2(r * 0.75, -r * 0.65), Vector2(r * 0.95, 0.0),
		Vector2(r * 0.8, r * 0.6), Vector2(r * 0.15, r * 0.85), Vector2(-r * 0.55, r * 0.8)
	])

	# Dark boulder outline
	draw_colored_polygon(pts, Color("183048"))

	# Deep glacial blue base
	var inner_pts: PackedVector2Array = pts.duplicate()
	for i: int in range(inner_pts.size()):
		inner_pts[i] = inner_pts[i] * 0.88 + Vector2(0, 0.8)
	draw_colored_polygon(inner_pts, Color("345c7e"))

	# Main upper frosty snow facet
	var upper_facet: PackedVector2Array = PackedVector2Array([
		Vector2(-r * 0.7, -r * 0.35), Vector2(-r * 0.35, -r * 0.75), Vector2(r * 0.1, -r * 0.8),
		Vector2(r * 0.6, -r * 0.5), Vector2(r * 0.45, 0.0), Vector2(-r * 0.1, r * 0.25),
		Vector2(-r * 0.6, 0.1)
	])
	draw_colored_polygon(upper_facet, Color("e6f6ff"))

	# Top highlight cap
	var top_cap: PackedVector2Array = PackedVector2Array([
		Vector2(-r * 0.5, -r * 0.5), Vector2(-r * 0.25, -r * 0.8), Vector2(r * 0.15, -r * 0.75),
		Vector2(r * 0.3, -r * 0.4), Vector2(-r * 0.1, -r * 0.25)
	])
	draw_colored_polygon(top_cap, Color("ffffff"))

	# Facet cut lines
	draw_line(Vector2(-r * 0.35, -r * 0.75), Vector2(-r * 0.1, r * 0.25), Color("6ca2c6"), 1.5)
	draw_line(Vector2(r * 0.1, -r * 0.8), Vector2(r * 0.45, 0.0), Color("6ca2c6"), 1.5)
	draw_line(Vector2(-r * 0.6, 0.1), Vector2(-r * 0.1, r * 0.25), Color("2e5270"), 1.5)

	# Twinkling diamond frost sparkles
	var glint_t: float = sin(_age * 6.0)
	var glint_sz1: float = 3.5 + glint_t * 1.5
	var glint_sz2: float = 3.5 - glint_t * 1.5

	var glint1_pos: Vector2 = Vector2(-r * 0.35, -r * 0.5)
	var glint2_pos: Vector2 = Vector2(r * 0.45, -r * 0.2)
	if variant == 1:
		glint1_pos = Vector2(-r * 0.45, -r * 0.3)
		glint2_pos = Vector2(r * 0.25, -r * 0.45)
	elif variant == 2:
		glint1_pos = Vector2(-r * 0.2, -r * 0.6)
		glint2_pos = Vector2(r * 0.5, 0.0)

	# Sparkle 1
	draw_line(glint1_pos - Vector2(glint_sz1, 0), glint1_pos + Vector2(glint_sz1, 0), Color.WHITE, 1.5)
	draw_line(glint1_pos - Vector2(0, glint_sz1), glint1_pos + Vector2(0, glint_sz1), Color.WHITE, 1.5)
	draw_circle(glint1_pos, glint_sz1 * 0.4, Color("8ae4ff"))

	# Sparkle 2
	draw_line(glint2_pos - Vector2(glint_sz2, 0), glint2_pos + Vector2(glint_sz2, 0), Color.WHITE, 1.5)
	draw_line(glint2_pos - Vector2(0, glint_sz2), glint2_pos + Vector2(0, glint_sz2), Color.WHITE, 1.5)
	draw_circle(glint2_pos, glint_sz2 * 0.4, Color("8ae4ff"))
