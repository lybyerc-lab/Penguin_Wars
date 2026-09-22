class_name BossBehavior
extends EnemyBehavior
## Locked warnings precede every attack. Cleaver hits cannot stun-lock a boss.
enum State { STALK, WINDUP, RUSH, RECOVER }
enum Attack { RUSH, VOLLEY, SLAM }
var state: State = State.STALK
var attack: Attack = Attack.RUSH
var remaining: float = 1.4
var direction := Vector2.RIGHT
var enraged: bool = false
var slam_radius: float = 155
var _sequence: int = 0
var _rank: int = 1

func movement(enemy: ArenaEnemy, target: PenguinPlayer, delta: float) -> Vector2:
	var boss := enemy as ArenaBoss
	_rank = boss.definition.rank
	enraged = _rank == 3 and boss.health.current <= boss.health.maximum * 0.5
	remaining -= delta
	match state:
		State.STALK:
			if remaining <= 0:
				attack = Attack.RUSH if _rank == 1 else (Attack.VOLLEY if _sequence % 2 == 1 else Attack.RUSH)
				if _rank == 3 and _sequence % 3 == 2:
					attack = Attack.SLAM
				_sequence += 1
				direction = boss.global_position.direction_to(target.global_position)
				state = State.WINDUP
				remaining = 0.8 if enraged else 1.1
				return Vector2.ZERO
			return boss.global_position.direction_to(target.global_position) * (90 if enraged else 65)
		State.WINDUP:
			if remaining <= 0:
				if attack == Attack.RUSH:
					state = State.RUSH
					remaining = 0.75
				elif attack == Attack.VOLLEY:
					_fire_volley(boss)
					_recover()
				else:
					for player: PenguinPlayer in boss.party.members(true):
						if boss.global_position.distance_to(player.global_position) <= slam_radius:
							player.health.take_damage(DamageEvent.new(boss.contact_damage))
					_recover()
		State.RUSH:
			if remaining <= 0:
				_recover()
			else:
				return direction * (430 if enraged else 340)
		State.RECOVER:
			if remaining <= 0:
				state = State.STALK
				remaining = 0.8 if enraged else 1.3
	return Vector2.ZERO

func shot_count() -> int:
	return 12 if enraged else 8

func _fire_volley(boss: ArenaBoss) -> void:
	for index: int in range(shot_count()):
		var shot := EnemySnowball.new()
		shot.party = boss.party
		shot.direction = Vector2.RIGHT.rotated(direction.angle() + TAU * index / shot_count())
		shot.damage = boss.contact_damage
		shot.speed = 240 if enraged else 190
		shot.position = boss.position + shot.direction * (boss.hit_radius + 12)
		boss.get_parent().add_child(shot)

func _recover() -> void:
	state = State.RECOVER
	remaining = 1.0 if enraged else 1.5

func contact_enabled() -> bool:
	return state == State.RUSH

func cancel() -> void:
	state = State.STALK
	remaining = 1.4
