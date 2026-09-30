class_name DiscoverySite
extends Node2D

signal discovered(definition: DiscoveryDefinition, player: PenguinPlayer, granted_slot: int)
enum State { CLOSED, DIGGING, AMBUSH, OPEN }
const GLINT_TEXTURE: Texture2D = preload("res://assets/fx/fx_discovery_glint.png")
const BURST_TEXTURE: Texture2D = preload("res://assets/fx/fx_snow_burst_6f.png")
const MOUND_CLOSED: Texture2D = preload("res://assets/discoveries/fcd_suspicious_mound_closed.png")
const MOUND_BURST: Texture2D = preload("res://assets/discoveries/fcd_suspicious_mound_burst.png")

var definition: DiscoveryDefinition
var party: PartyRoster
var encounter: EncounterDirector
var loot: ArenaLoot
var session: RunSession
var claimed: bool = false
var state: State = State.CLOSED
var progress: float = 0.0
var _prop: Sprite2D
var _glints: Array[Sprite2D] = []
var _mounds: Array[Sprite2D] = []
var _ambush_alive: Dictionary = {}
var _glint_clock: float = 0.0
var _burst_clock: float = -1.0
var _burst: Sprite2D

func _ready() -> void:
	assert(definition != null)
	position = definition.position
	_prop = Sprite2D.new()
	_prop.name = "Prop"
	_prop.texture = definition.open_texture if claimed else definition.closed_texture
	_prop.scale = Vector2(0.6328, 0.7931)
	_prop.offset = _texture_offset(_prop.texture)
	add_child(_prop)
	for offset: Vector2 in PackedVector2Array([definition.glint_offset]) + definition.extra_glint_offsets:
		var glint := Sprite2D.new()
		glint.texture = GLINT_TEXTURE
		glint.position = offset
		glint.z_index = 1
		var material := CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glint.material = material
		add_child(glint)
		_glints.append(glint)
	_burst = Sprite2D.new()
	_burst.texture = BURST_TEXTURE
	_burst.hframes = 6
	_burst.visible = false
	_burst.position = Vector2(40, -30)
	_burst.z_index = 2
	add_child(_burst)
	for mound_position: Vector2 in definition.mound_positions:
		var mound := Sprite2D.new()
		mound.texture = MOUND_CLOSED
		mound.scale = Vector2(0.6328, 0.7931)
		mound.offset = Vector2(2, -2)
		mound.position = mound_position - definition.position
		add_child(mound)
		_mounds.append(mound)
	if claimed:
		state = State.OPEN
		for glint: Sprite2D in _glints: glint.visible = false
	queue_redraw()

func _physics_process(delta: float) -> void:
	_update_fx(delta)
	if state not in [State.CLOSED, State.DIGGING]: return
	var centre: Vector2 = global_position + definition.ring_offset
	var nearby: Array[PenguinPlayer] = []
	for player: PenguinPlayer in party.members(true):
		if player.global_position.distance_to(centre) <= definition.dig_radius:
			nearby.append(player)
	if nearby.is_empty():
		progress = maxf(0.0, progress - 0.5 * delta)
		if progress <= 0.0: state = State.CLOSED
	else:
		state = State.DIGGING
		progress += delta / definition.dig_time * (1.5 if nearby.size() >= 2 else 1.0)
		if progress >= 1.0:
			_complete(party.nearest_alive(centre))
	queue_redraw()

func _update_fx(delta: float) -> void:
	_glint_clock = fmod(_glint_clock + delta, 2.4)
	var pulse: float = sin(clampf(_glint_clock / 0.5, 0.0, 1.0) * PI) * 0.5
	for glint: Sprite2D in _glints:
		glint.visible = state == State.CLOSED
		glint.scale = Vector2.ONE * pulse
		glint.rotation = deg_to_rad(30.0) * clampf(_glint_clock / 0.5, 0.0, 1.0)
	if _burst_clock >= 0.0:
		_burst_clock += delta
		_burst.frame = mini(5, floori(_burst_clock * 14.0))
		_burst.visible = _burst_clock < 6.0 / 14.0

func _complete(player: PenguinPlayer) -> void:
	if player == null: return
	progress = 1.0
	if definition.kind == DiscoveryDefinition.Kind.WEAPON_CACHE:
		_open_prop()
		var granted_slot: int = player.weapon_rack.add_weapon(definition.reward_weapon)
		if granted_slot < 0:
			loot.spawn_pickup(global_position + Vector2(0, 16), RunPickup.Kind.SNOWFLAKE, definition.salvage_snow)
		_claim(player, granted_slot)
	else:
		state = State.AMBUSH
		for mound: Sprite2D in _mounds:
			mound.texture = MOUND_BURST
			mound.offset = Vector2(4, -1)
		var entries: Array[Dictionary] = []
		for index: int in range(mini(definition.ambush.size(), definition.ambush_positions.size())):
			entries.append({"scene": definition.ambush[index], "position": definition.ambush_positions[index]})
		for member: ArenaEnemy in encounter.spawn_ambush(entries):
			var key: int = member.get_instance_id()
			_ambush_alive[key] = true
			member.defeated.connect(_on_ambush_gone.bind(key), CONNECT_ONE_SHOT)
			member.tree_exited.connect(_on_ambush_gone.bind(null, key), CONNECT_ONE_SHOT)
		if _ambush_alive.is_empty(): _finish_ambush(player)
	queue_redraw()

func _on_ambush_gone(_first: Variant = null, _second: Variant = null, explicit_key: int = 0) -> void:
	if not is_inside_tree(): return
	var key: int = explicit_key
	if key == 0 and _second is int: key = _second
	if key == 0 and _first is int: key = _first
	_ambush_alive.erase(key)
	if state == State.AMBUSH and _ambush_alive.is_empty():
		_finish_ambush(party.nearest_alive(global_position))

func _finish_ambush(player: PenguinPlayer) -> void:
	_open_prop()
	loot.spawn_pickup(global_position + Vector2(-10, 30), RunPickup.Kind.SNOWFLAKE, definition.reward_snow)
	loot.spawn_pickup(global_position + Vector2(24, 26), RunPickup.Kind.HEALTH, definition.reward_health)
	_claim(player, -1)

func _open_prop() -> void:
	state = State.OPEN
	_prop.texture = definition.open_texture
	_prop.offset = _texture_offset(_prop.texture)
	for glint: Sprite2D in _glints: glint.visible = false
	_burst_clock = 0.0

func _claim(player: PenguinPlayer, granted_slot: int) -> void:
	session.claim_discovery(definition.id)
	discovered.emit(definition, player, granted_slot)

func _draw() -> void:
	if state not in [State.CLOSED, State.DIGGING]: return
	var visible_alpha: float = 0.0
	for player: PenguinPlayer in party.members(true):
		if player.global_position.distance_to(global_position) <= 150.0: visible_alpha = 0.35
	draw_set_transform(definition.ring_offset, 0.0, Vector2(1.0, 0.42))
	draw_arc(Vector2.ZERO, definition.dig_radius, 0.0, TAU, 48, Color("f4fbff", visible_alpha), 2.0)
	if progress > 0.0:
		draw_arc(Vector2.ZERO, definition.dig_radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, Color("8fe6f2", 0.92), 3.0)
	draw_set_transform(Vector2.ZERO)

func _texture_offset(texture: Texture2D) -> Vector2:
	if texture == null: return Vector2.ZERO
	var name: String = texture.resource_path.get_file()
	match name:
		"fcd_whalers_cache_closed.png": return Vector2(124, -61)
		"fcd_whalers_cache_open.png": return Vector2(2, -13)
		"fcd_glint_hoard_closed.png": return Vector2(15, -26)
		"fcd_glint_hoard_open.png": return Vector2(20, -50)
	return Vector2.ZERO
