class_name EncounterDirector
extends Node
## Owns encounter lifecycle; enemy scenes own behavior and combat.
signal state_changed
signal enemy_defeated(event: DamageEvent)
signal loot_available(location: Vector2)
signal completed
signal wave_cleared(wave_number: int)

enum State { READY, SPAWNING, CLEARING, INTERMISSION, COMPLETE, FAILED }
@export var definition: EncounterDefinition
@export var auto_advance: bool = false
var party: PartyRoster
var actor_root: Node2D
var arena_bounds := Rect2(-540, -260, 1080, 520)
var state: State = State.READY
var wave: int = 0
var alive_count: int = 0
var _left: int = 0
var _timer: float = 0.0
var _spawn_index: int = 0
var _rng := RandomNumberGenerator.new()

func start() -> void:
	assert(party != null and actor_root != null and definition != null)
	_rng.seed = definition.run_seed
	_begin_wave()

func _begin_wave() -> void:
	wave += 1
	_spawn_index = 0
	_left = definition.base_count + (wave - 1) * 2 + maxi(0, party.members().size() - 1) * 2
	_timer = 1.0
	state = State.SPAWNING
	state_changed.emit()

func _physics_process(delta: float) -> void:
	if state in [State.READY, State.COMPLETE, State.FAILED]:
		return
	if party.members(true).is_empty():
		state = State.FAILED
		_clear_projectiles()
		state_changed.emit()
		return
	_timer -= delta
	if state == State.SPAWNING and _timer <= 0.0:
		_spawn_enemy()
		_left -= 1
		_timer = definition.spawn_interval
		if _left == 0:
			state = State.CLEARING
	elif state == State.CLEARING and alive_count == 0:
		_clear_projectiles()
		if wave >= definition.wave_count:
			state = State.COMPLETE
			completed.emit()
		else:
			state = State.INTERMISSION
			_timer = 3.0
		wave_cleared.emit(wave)
		state_changed.emit()
	elif state == State.INTERMISSION and auto_advance and _timer <= 0.0:
		_begin_wave()

func advance_wave() -> void:
	if state == State.INTERMISSION:
		_begin_wave()

func _spawn_enemy() -> void:
	var selected: PackedScene = definition.enemy_scene
	# Fixed introduction cadence is predictable; placement remains seeded.
	if wave >= 2 and _spawn_index % 4 == 3 and definition.ranged_scene != null:
		selected = definition.ranged_scene
	elif _spawn_index % 3 == 2 and definition.charger_scene != null:
		selected = definition.charger_scene
	_spawn_index += 1
	var enemy := selected.instantiate() as ArenaEnemy
	enemy.party = party
	enemy.arena_bounds = arena_bounds
	# Pick the safest of several perimeter points to avoid spawning on a player.
	var safest := Vector2.ZERO
	var best: float = -1.0
	for attempt: int in range(12):
		var angle: float = _rng.randf_range(0.0, TAU)
		var half_size: Vector2 = arena_bounds.size * 0.5 - Vector2(25, 25)
		var candidate: Vector2 = arena_bounds.get_center() + Vector2(cos(angle), sin(angle)) * half_size
		var nearest: PenguinPlayer = party.nearest_alive(candidate)
		var distance: float = candidate.distance_squared_to(nearest.global_position) if nearest != null else INF
		if distance > best:
			best = distance
			safest = candidate
	enemy.position = safest
	enemy.defeated.connect(_on_enemy_defeated)
	actor_root.add_child(enemy)
	alive_count += 1

func _on_enemy_defeated(enemy: ArenaEnemy, event: DamageEvent) -> void:
	alive_count -= 1
	enemy_defeated.emit(event)
	loot_available.emit(enemy.global_position)

func _clear_projectiles() -> void:
	for node: Node in actor_root.get_children():
		if node is EnemySnowball or node is CastleSnowball:
			node._expire()
