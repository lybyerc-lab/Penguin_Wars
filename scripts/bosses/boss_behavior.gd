class_name BossBehavior
extends EnemyBehavior
## Boss attack states and telegraphs. Every attack is preceded by a locked warning.
## Heavy damage taken during windup cannot cancel the attack.

enum State { STALK, WINDUP, RUSH, RECOVER }
enum Attack { RUSH, VOLLEY, SLAM }

const RUSH_LANE: float = 310.0

var state: State = State.STALK
var attack: Attack = Attack.RUSH
var remaining: float = 1.4
var direction := Vector2.RIGHT
var enraged: bool = false
var slam_radius: float = 155.0
var _sequence: int = 0
var _rank: int = 1

func movement(enemy: ArenaEnemy, target: PenguinPlayer, delta: float) -> Vector2:
	var boss := enemy as BossActor
	if boss == null or boss.boss_definition == null:
		return Vector2.ZERO
	_rank = boss.boss_definition.rank
	var was_enraged: bool = enraged
	enraged = _rank == 3 and boss.health.current <= boss.health.maximum * 0.5
	if enraged != was_enraged:
		boss.announce()
	remaining -= delta
	match state:
		State.STALK:
			if remaining <= 0.0:
				attack = _next_attack()
				_sequence += 1
				direction = boss.global_position.direction_to(target.global_position)
				state = State.WINDUP
				remaining = 0.8 if enraged else 1.1
				return Vector2.ZERO
			return boss.global_position.direction_to(target.global_position) * (90.0 if enraged else 65.0)
		State.WINDUP:
			if remaining <= 0.0:
				if attack == Attack.RUSH:
					state = State.RUSH
					remaining = 0.75
				elif attack == Attack.VOLLEY:
					_fire_volley(boss)
					_recover()
				else:
					_slam(boss)
					_recover()
		State.RUSH:
			if remaining <= 0.0:
				_recover()
			else:
				return direction * (430.0 if enraged else 340.0)
		State.RECOVER:
			if remaining <= 0.0:
				state = State.STALK
				remaining = 0.8 if enraged else 1.3
	return Vector2.ZERO

func shot_count() -> int:
	return 12 if enraged else 8

func _next_attack() -> Attack:
	if _rank == 1:
		return Attack.RUSH
	if _rank == 3 and _sequence % 3 == 2:
		return Attack.SLAM
	return Attack.VOLLEY if _sequence % 2 == 1 else Attack.RUSH

func _slam(boss: BossActor) -> void:
	for player: PenguinPlayer in boss.party.members(true):
		if boss.global_position.distance_to(player.global_position) <= slam_radius:
			player.health.take_damage(DamageEvent.new(boss.contact_damage))

func _fire_volley(boss: BossActor) -> void:
	for index: int in range(shot_count()):
		var shot := EnemySnowball.new()
		shot.party = boss.party
		shot.room_bounds = boss.room_bounds
		shot.direction = Vector2.RIGHT.rotated(direction.angle() + TAU * index / shot_count())
		shot.damage = boss.projectile_damage
		shot.speed = 240.0 if enraged else 190.0
		shot.position = boss.position + shot.direction * (boss.hit_radius + 12.0)
		boss.get_parent().add_child(shot)

func _recover() -> void:
	state = State.RECOVER
	remaining = 1.0 if enraged else 1.5

func contact_enabled() -> bool:
	return state == State.RUSH

func cancel() -> void:
	state = State.STALK
	remaining = 1.4
