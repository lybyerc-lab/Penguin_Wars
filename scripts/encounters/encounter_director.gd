class_name EncounterDirector
extends Node
## Owns encounter lifecycle; enemy scenes own behavior and combat.
signal state_changed
signal enemy_defeated(event: DamageEvent)
signal loot_available(location: Vector2)
signal completed
signal wave_cleared(wave_number: int)
signal boss_started(boss: ArenaBoss)
signal boss_reward(amount: int)

enum State { READY, SPAWNING, CLEARING, INTERMISSION, COMPLETE, FAILED, BOSS }
@export var definition: EncounterDefinition
@export var auto_advance: bool = false
var party: PartyRoster
var actor_root: Node2D
## Perimeter ellipse the room owns; defaults to the original centered arena.
var spawn_ring := Vector2(515.0, 235.0)
var spawn_center := Vector2.ZERO
## Movement clamp handed to every enemy this director spawns.
var actor_bounds := Rect2(-540, -260, 1080, 520)
var state: State = State.READY
var wave: int = 0
var alive_count: int = 0
var active_boss: ArenaBoss
var _left: int = 0
var _timer: float = 0.0
var _spawn_index: int = 0
var _rng := RandomNumberGenerator.new()

## Return to a pre-start state so one director can run a second room.
func reset() -> void:
	_clear_projectiles()
	for node: Node in actor_root.get_children() if actor_root != null else []:
		if node is ArenaEnemy:
			node.queue_free()
	state = State.READY
	wave = 0
	alive_count = 0
	active_boss = null
	_left = 0
	_timer = 0.0
	_spawn_index = 0

func start() -> void:
	assert(party != null and actor_root != null and definition != null)
	wave = 0
	alive_count = 0
	active_boss = null
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
		# Pay and bank the wave before deciding what follows it.
		wave_cleared.emit(wave)
		if wave < definition.wave_count:
			state = State.INTERMISSION
			_timer = 3.0
			state_changed.emit()
		elif definition.boss != null:
			_begin_boss()
		else:
			_finish()
	elif state == State.BOSS and alive_count == 0:
		_finish()
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
	enemy.arena_bounds = actor_bounds
	# Applied before the tree sets current from maximum.
	enemy.get_node("Health").maximum *= definition.difficulty_multiplier
	enemy.contact_damage *= definition.difficulty_multiplier
	enemy.projectile_damage *= definition.difficulty_multiplier
	# Pick the safest of several perimeter points to avoid spawning on a player.
	var safest := Vector2.ZERO
	var best: float = -1.0
	for attempt: int in range(12):
		var angle: float = _rng.randf_range(0.0, TAU)
		var candidate := spawn_center + Vector2(cos(angle) * spawn_ring.x, sin(angle) * spawn_ring.y)
		var nearest: PenguinPlayer = party.nearest_alive(candidate)
		var distance: float = candidate.distance_squared_to(nearest.global_position) if nearest != null else INF
		if distance > best:
			best = distance
			safest = candidate
	enemy.position = safest
	enemy.defeated.connect(_on_enemy_defeated)
	actor_root.add_child(enemy)
	alive_count += 1

## The boss enters alone, from the corner furthest from the living party, and
## is the only thing standing between the room and its exit.
func _begin_boss() -> void:
	state = State.BOSS
	var boss := preload("res://scenes/actors/boss.tscn").instantiate() as ArenaBoss
	boss.party = party
	boss.configure(definition.boss, definition.difficulty_multiplier, party.members().size())
	boss.arena_bounds = actor_bounds.grow(-boss.hit_radius)
	var best: float = -1.0
	for corner: Vector2 in [boss.arena_bounds.position, boss.arena_bounds.end, Vector2(boss.arena_bounds.position.x, boss.arena_bounds.end.y), Vector2(boss.arena_bounds.end.x, boss.arena_bounds.position.y)]:
		var nearest: PenguinPlayer = party.nearest_alive(corner)
		var distance: float = corner.distance_squared_to(nearest.global_position) if nearest != null else INF
		if distance > best:
			best = distance
			boss.position = corner
	boss.defeated.connect(_on_enemy_defeated)
	boss.defeated.connect(func(_actor: ArenaEnemy, _event: DamageEvent) -> void: boss_reward.emit(definition.boss.reward))
	actor_root.add_child(boss)
	active_boss = boss
	alive_count = 1
	boss_started.emit(boss)
	state_changed.emit()

func _finish() -> void:
	_clear_projectiles()
	active_boss = null
	state = State.COMPLETE
	completed.emit()
	state_changed.emit()

func _on_enemy_defeated(enemy: ArenaEnemy, event: DamageEvent) -> void:
	alive_count -= 1
	enemy_defeated.emit(event)
	loot_available.emit(enemy.global_position)

func _clear_projectiles() -> void:
	for node: Node in actor_root.get_children():
		if node is EnemySnowball or node is CastleSnowball:
			node._expire()
