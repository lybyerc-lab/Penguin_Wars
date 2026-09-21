class_name RangedBehavior
extends EnemyBehavior

enum State { POSITION, WINDUP, RECOVER }
@export var windup_time: float = 0.7
@export var shot_cooldown: float = 1.65
var state: State = State.POSITION
var remaining: float = 0.9
var direction := Vector2.RIGHT

func movement(enemy: ArenaEnemy, target: PenguinPlayer, delta: float) -> Vector2:
	remaining = maxf(0.0, remaining - delta)
	if state == State.WINDUP:
		if remaining <= 0.0:
			var snowball := EnemySnowball.new()
			snowball.party = enemy.party
			snowball.direction = direction
			snowball.position = enemy.position + direction * 28.0
			enemy.get_parent().add_child(snowball)
			state = State.RECOVER
			remaining = shot_cooldown
		return Vector2.ZERO
	if state == State.RECOVER and remaining <= 0.0:
		state = State.POSITION
	var distance: float = enemy.global_position.distance_to(target.global_position)
	if state == State.POSITION and remaining <= 0.0 and distance <= 370.0:
		direction = enemy.global_position.direction_to(target.global_position)
		state = State.WINDUP
		remaining = windup_time
		return Vector2.ZERO
	if distance < 190.0:
		return target.global_position.direction_to(enemy.global_position) * enemy.speed
	if distance > 265.0:
		return enemy.global_position.direction_to(target.global_position) * enemy.speed
	return Vector2.ZERO

func contact_enabled() -> bool:
	return false

func on_damage(event: DamageEvent) -> void:
	if event.impulse.length() >= 250.0 and state == State.WINDUP:
		state = State.RECOVER
		remaining = shot_cooldown

func cancel() -> void:
	state = State.POSITION
	remaining = 0.9
