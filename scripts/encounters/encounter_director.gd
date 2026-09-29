class_name EncounterDirector
extends Node
## Owns encounter lifecycle; enemy scenes own behavior and combat.
signal state_changed
signal enemy_defeated(event: DamageEvent)
signal loot_available(location: Vector2)
signal completed
signal wave_cleared(wave_number: int)
signal boss_started(boss: BossActor)
signal boss_defeated(boss: BossActor)
signal boss_reward(amount: int)

enum State { READY, SPAWNING, CLEARING, INTERMISSION, COMPLETE, FAILED, BOSS }
const SPAWN_SECTOR_COUNT: int = 8
const SECTOR_ATTEMPTS: int = 12
const SPAWN_EDGE_MARGIN: float = 48.0
const WORLD_COLLISION_MASK: int = 1
@export var definition: EncounterDefinition
@export var auto_advance: bool = false
var party: PartyRoster
var actor_root: Node2D
## Perimeter ellipse the room owns; defaults to the original centered arena.
var spawn_ring := Vector2(515.0, 235.0)
var spawn_center := Vector2.ZERO
## Movement clamp handed to every enemy this director spawns.
var actor_bounds := Rect2(-540, -260, 1080, 520)
## Whole-run dials. Never null: an identity default means no run modifiers.
var modifiers := RunModifiers.new()
var state: State = State.READY
var wave: int = 0
var alive_count: int = 0
var active_boss: BossActor
var _left: int = 0
var _timer: float = 0.0
var _wave_duration: float = 0.0
var _wave_time_remaining: float = 0.0
var _spawn_index: int = 0
var _rng := RandomNumberGenerator.new()
var _pressure_sectors := PackedInt32Array()

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
	_wave_duration = 0.0
	_wave_time_remaining = 0.0
	_spawn_index = 0
	_pressure_sectors = PackedInt32Array()

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
	_left = definition.population_for_wave(wave, party.members().size())
	_configure_pressure_sectors()
	_wave_duration = definition.duration_for_wave(wave)
	_wave_time_remaining = _wave_duration
	_timer = 0.0 if uses_timed_waves() else 1.0
	state = State.SPAWNING
	state_changed.emit()

## Read-only simulation seams for timed HUD and tests. Legacy encounters report
## zero duration/progress rather than exposing the old spawn timer.
func uses_timed_waves() -> bool:
	return definition != null and definition.uses_timed_waves()

func wave_time_remaining() -> float:
	return maxf(0.0, _wave_time_remaining) if uses_timed_waves() else 0.0

func wave_duration() -> float:
	return _wave_duration if uses_timed_waves() else 0.0

func wave_progress() -> float:
	return clampf(1.0 - _wave_time_remaining / _wave_duration, 0.0, 1.0) if _wave_duration > 0.0 else 0.0

func intermission_time_remaining() -> float:
	return maxf(0.0, _timer) if state == State.INTERMISSION else 0.0

func timed_alive_cap() -> int:
	return definition.timed_max_alive + maxi(0, party.members().size() - 1) * 2

func _physics_process(delta: float) -> void:
	if state in [State.READY, State.COMPLETE, State.FAILED]:
		return
	if party.members(true).is_empty():
		state = State.FAILED
		_clear_projectiles()
		state_changed.emit()
		return
	if state == State.SPAWNING and uses_timed_waves():
		_wave_time_remaining -= delta
		if _wave_time_remaining <= 0.0:
			_end_timed_wave()
			return
		_timer -= delta
		if _timer <= 0.0 and alive_count < timed_alive_cap():
			_spawn_enemy()
			_timer = definition.spawn_interval
	elif state == State.SPAWNING:
		_timer -= delta
		if _timer <= 0.0:
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
	elif state == State.INTERMISSION:
		_timer -= delta
		if (auto_advance or uses_timed_waves()) and _timer <= 0.0:
			_begin_wave()

func advance_wave() -> void:
	if state == State.INTERMISSION and not uses_timed_waves():
		_begin_wave()

## Timer expiration is not a kill: ordinary enemies leave without defeated,
## loot, XP, or reward callbacks, then normal wave completion occurs once.
func _end_timed_wave() -> void:
	_wave_time_remaining = 0.0
	_despawn_ordinary_enemies()
	_clear_projectiles()
	wave_cleared.emit(wave)
	if wave < definition.wave_count:
		state = State.INTERMISSION
		_timer = definition.intermission_duration
		state_changed.emit()
	elif definition.boss != null:
		_begin_boss()
	else:
		_finish()

func _despawn_ordinary_enemies() -> void:
	for node: Node in actor_root.get_children():
		if node is ArenaEnemy and not node is BossActor:
			node.queue_free()
	alive_count = 0

func _spawn_enemy() -> void:
	var spawn_event_index: int = _spawn_index
	var selected: PackedScene = definition.enemy_scene
	# Fixed introduction cadence stays predictable; room data decides when each
	# role enters and how many may pressure the screen at once.
	if (
		wave >= definition.ranged_intro_wave
		and _spawn_index % 4 == 3
		and definition.ranged_scene != null
		and _alive_ranged_count() < definition.ranged_cap
	):
		selected = definition.ranged_scene
	elif (
		wave >= definition.charger_intro_wave
		and _spawn_index % 3 == 2
		and definition.charger_scene != null
		and _alive_charger_count() < definition.charger_cap
	):
		selected = definition.charger_scene
	_spawn_index += 1
	var enemy := selected.instantiate() as ArenaEnemy
	enemy.party = party
	enemy.arena_bounds = actor_bounds
	enemy.room_bounds = actor_bounds
	_apply_scaling(enemy)
	enemy.position = _spawn_position(spawn_event_index)
	enemy.defeated.connect(_on_enemy_defeated)
	actor_root.add_child(enemy)
	alive_count += 1

func _configure_pressure_sectors() -> void:
	_pressure_sectors = PackedInt32Array()
	if definition == null or not definition.split_spawn_pressure:
		return
	var first: int = _rng.randi_range(0, SPAWN_SECTOR_COUNT - 1)
	# Three to five eighth-turns keeps the lanes at least 135 degrees apart.
	var separation: int = _rng.randi_range(3, 5)
	_pressure_sectors.append(first)
	_pressure_sectors.append((first + separation) % SPAWN_SECTOR_COUNT)

func _spawn_position(spawn_event_index: int) -> Vector2:
	if definition == null or not definition.split_spawn_pressure:
		return _legacy_spawn_position()
	if _pressure_sectors.size() != 2:
		_configure_pressure_sectors()
	var primary_sector: int = _pressure_sectors[spawn_event_index % 2]
	# Stay in the selected pressure lane when possible. Adjacent sectors are
	# deterministic safety fallbacks for authored blockers or shoreline.
	for offset: int in [0, 1, -1, 2, -2, 3, -3, 4]:
		var result: Dictionary = _best_sector_candidate(posmod(primary_sector + offset, SPAWN_SECTOR_COUNT))
		if bool(result.get("found", false)):
			return result["position"]
	return _safe_interior_fallback()

func _best_sector_candidate(sector: int) -> Dictionary:
	var sector_width: float = TAU / float(SPAWN_SECTOR_COUNT)
	var safest := Vector2.ZERO
	var best: float = -1.0
	for attempt: int in range(SECTOR_ATTEMPTS):
		var angle: float = (float(sector) + 0.5) * sector_width
		angle += _rng.randf_range(-sector_width * 0.36, sector_width * 0.36)
		var candidate := spawn_center + Vector2(cos(angle) * spawn_ring.x, sin(angle) * spawn_ring.y)
		if not _spawn_candidate_is_safe(candidate):
			continue
		var nearest: PenguinPlayer = party.nearest_alive(candidate)
		var distance: float = candidate.distance_squared_to(nearest.global_position) if nearest != null else INF
		if distance > best:
			best = distance
			safest = candidate
	return {"found": best >= 0.0, "position": safest}

func _legacy_spawn_position() -> Vector2:
	# Existing rooms retain the safest of several global perimeter points.
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
	return safest

func _spawn_candidate_is_safe(candidate: Vector2) -> bool:
	if not actor_bounds.grow(-SPAWN_EDGE_MARGIN).has_point(candidate):
		return false
	if actor_root == null or not actor_root.is_inside_tree():
		return true
	var space: PhysicsDirectSpaceState2D = actor_root.get_world_2d().direct_space_state
	var point := PhysicsPointQueryParameters2D.new()
	point.position = candidate
	point.collision_mask = WORLD_COLLISION_MASK
	point.collide_with_areas = false
	point.collide_with_bodies = true
	if not space.intersect_point(point, 1).is_empty():
		return false
	var destination: Vector2 = _party_center()
	if candidate.distance_squared_to(destination) < 1.0:
		return false
	var ray := PhysicsRayQueryParameters2D.create(candidate, destination, WORLD_COLLISION_MASK)
	ray.collide_with_areas = false
	ray.collide_with_bodies = true
	return space.intersect_ray(ray).is_empty()

func _party_center() -> Vector2:
	if party == null:
		return spawn_center
	var living: Array[PenguinPlayer] = party.members(true)
	if living.is_empty():
		return spawn_center
	var total := Vector2.ZERO
	for player: PenguinPlayer in living:
		total += player.global_position
	return total / float(living.size())

func _safe_interior_fallback() -> Vector2:
	var safe_bounds: Rect2 = actor_bounds.grow(-SPAWN_EDGE_MARGIN)
	var safest := spawn_center
	var best: float = -1.0
	for y_step: int in range(1, 8):
		for x_step: int in range(1, 10):
			var candidate := Vector2(
				lerpf(safe_bounds.position.x, safe_bounds.end.x, float(x_step) / 10.0),
				lerpf(safe_bounds.position.y, safe_bounds.end.y, float(y_step) / 8.0)
			)
			if not _spawn_candidate_is_safe(candidate):
				continue
			var nearest: PenguinPlayer = party.nearest_alive(candidate)
			var distance: float = candidate.distance_squared_to(nearest.global_position) if nearest != null else INF
			if distance > best:
				best = distance
				safest = candidate
	if best < 0.0:
		push_warning("Encounter could not find a collision-clear spawn point")
	return safest

func _alive_charger_count() -> int:
	var count: int = 0
	for node: Node in actor_root.get_children():
		if node is ArenaEnemy and (node as ArenaEnemy).behavior is ChargeBehavior:
			count += 1
	return count

func _alive_ranged_count() -> int:
	var count: int = 0
	for node: Node in actor_root.get_children():
		if node is ArenaEnemy and (node as ArenaEnemy).behavior is RangedBehavior:
			count += 1
	return count

## Room and run scaling, applied identically to every enemy including a boss.
## Called before the node enters the tree, where Health takes current from
## maximum, so a scaled enemy starts at full scaled health.
func _apply_scaling(enemy: ArenaEnemy) -> void:
	var health: Health = enemy.get_node("Health")
	health.maximum *= health_scale()
	enemy.contact_damage *= damage_scale()
	enemy.projectile_damage *= damage_scale()

func health_scale() -> float:
	return definition.difficulty_multiplier * modifiers.enemy_health_scale

func damage_scale() -> float:
	return definition.difficulty_multiplier * modifiers.enemy_damage_scale

## The boss enters alone, from the corner furthest from the living party, and
## is the only thing standing between the room and its exit. The director knows
## nothing about how a boss fights: it instances the scene the definition names,
## hands it the definition and the party size, and treats it as one more enemy.
func _begin_boss() -> void:
	var boss_data: BossDefinition = definition.boss
	var boss := boss_data.scene.instantiate() as BossActor if boss_data.scene != null else null
	if boss == null:
		# A room that cannot spawn its boss must still be completable.
		push_error("Encounter boss '%s' does not instance a BossActor" % boss_data.id)
		_finish()
		return
	state = State.BOSS
	boss.party = party
	boss.configure(boss_data, party.members().size())
	_apply_scaling(boss)
	# A large body is inset so it cannot overhang the wall, but its shots still
	# belong to the whole room.
	boss.room_bounds = actor_bounds
	boss.arena_bounds = actor_bounds.grow(-boss.hit_radius)
	var best: float = -1.0
	for corner: Vector2 in [boss.arena_bounds.position, boss.arena_bounds.end, Vector2(boss.arena_bounds.position.x, boss.arena_bounds.end.y), Vector2(boss.arena_bounds.end.x, boss.arena_bounds.position.y)]:
		var nearest: PenguinPlayer = party.nearest_alive(corner)
		var distance: float = corner.distance_squared_to(nearest.global_position) if nearest != null else INF
		if distance > best:
			best = distance
			boss.position = corner
	boss.defeated.connect(_on_enemy_defeated)
	boss.defeated.connect(func(actor: ArenaEnemy, _event: DamageEvent) -> void:
		boss_defeated.emit(actor as BossActor)
		boss_reward.emit(boss_data.reward))
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
	if actor_root == null:
		return
	for node: Node in actor_root.get_children():
		if node is CastleSnowball or node.is_in_group("enemy_projectiles"):
			if node.has_method("_expire"):
				node.call("_expire")
			else:
				node.queue_free()
