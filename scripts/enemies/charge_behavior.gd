class_name ChargeBehavior
extends EnemyBehavior

enum State { APPROACH, WINDUP, CHARGE, RECOVER }
@export var windup_time: float = 0.75
@export var charge_speed: float = 360.0
@export var charge_time: float = 0.65
@export var recovery_time: float = 1.1
## Phase A Tuskbulls opt into a longer punish window when their committed lane
## hits solid world collision. Ordinary chargers keep the old behavior.
@export var crash_on_world_collision: bool = false
@export var crash_recovery_time: float = 1.55
## Provisional Phase A tuning: authored soft snow slows a committed charge to 60% speed.
## Exposed here so the phone playtest can tune one number without changing the terrain seam.
@export_range(0.1, 1.0, 0.05) var soft_charge_speed_multiplier: float = 0.60
var state: State = State.APPROACH
var remaining: float = 0.0
var direction := Vector2.RIGHT
var _soft_charge_zone_depth: int = 0

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
				var speed_scale := soft_charge_speed_multiplier if _soft_charge_zone_depth > 0 else 1.0
				return direction * charge_speed * speed_scale
		State.RECOVER:
			if remaining <= 0.0:
				state = State.APPROACH
	return Vector2.ZERO

func contact_enabled() -> bool:
	return state in [State.APPROACH, State.CHARGE]

func on_world_collision(hard_impact: bool = true) -> void:
	if crash_on_world_collision and hard_impact and state == State.CHARGE:
		state = State.RECOVER
		remaining = crash_recovery_time

func enter_soft_charge_zone() -> void:
	_soft_charge_zone_depth += 1

func exit_soft_charge_zone() -> void:
	_soft_charge_zone_depth = maxi(0, _soft_charge_zone_depth - 1)

func soft_charge_active() -> bool:
	return _soft_charge_zone_depth > 0

func on_damage(event: DamageEvent) -> void:
	# Heavy hits interrupt a rush; light hits still push the actor.
	if event.impulse.length() >= 250.0 and state in [State.WINDUP, State.CHARGE]:
		state = State.RECOVER
		remaining = recovery_time

func cancel() -> void:
	state = State.APPROACH
	remaining = 0.0
