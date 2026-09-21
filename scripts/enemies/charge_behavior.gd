class_name ChargeBehavior
extends EnemyBehavior

enum State { APPROACH, WINDUP, CHARGE, RECOVER }
@export var windup_time: float = 0.75
@export var charge_speed: float = 360.0
@export var charge_time: float = 0.65
@export var recovery_time: float = 1.1
var state: State = State.APPROACH
var remaining: float = 0.0
var direction := Vector2.RIGHT

func movement(enemy: ArenaEnemy, target: PenguinPlayer, delta: float) -> Vector2:
	remaining = maxf(0.0, remaining - delta)
	match state:
		State.APPROACH:
			if enemy.global_position.distance_to(target.global_position) <= 255.0:
				direction = enemy.global_position.direction_to(target.global_position)
				state = State.WINDUP
				remaining = windup_time
				return Vector2.ZERO
			return enemy.global_position.direction_to(target.global_position) * enemy.speed
		State.WINDUP:
			if remaining <= 0.0:
				state = State.CHARGE
				remaining = charge_time
				return direction * charge_speed
		State.CHARGE:
			if remaining <= 0.0:
				state = State.RECOVER
				remaining = recovery_time
			else:
				return direction * charge_speed
		State.RECOVER:
			if remaining <= 0.0:
				state = State.APPROACH
	return Vector2.ZERO

func contact_enabled() -> bool:
	return state in [State.APPROACH, State.CHARGE]

func on_damage(event: DamageEvent) -> void:
	# Heavy cleaver hits interrupt a rush; light lance hits still push the actor.
	if event.impulse.length() >= 250.0 and state in [State.WINDUP, State.CHARGE]:
		state = State.RECOVER
		remaining = recovery_time

func cancel() -> void:
	state = State.APPROACH
	remaining = 0.0
