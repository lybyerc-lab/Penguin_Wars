class_name SkuaSlingerBehavior
extends RangedBehavior
## Frozen Coast artillery variant: lock a landing point during the windup, then
## lob an ice egg there. The visible arc/ring is presentation of this exact
## locked point, so the telegraph and damage cannot disagree.

@export var preferred_range: float = 285.0
@export var retreat_range: float = 185.0
@export var attack_range: float = 390.0
@export var egg_travel_time: float = 0.62
@export var landing_radius: float = 42.0
var locked_target := Vector2.ZERO

func movement(enemy: ArenaEnemy, target: PenguinPlayer, delta: float) -> Vector2:
	remaining = maxf(0.0, remaining - delta)
	if state == State.WINDUP:
		if remaining <= 0.0:
			var egg := SkuaIceEgg.new()
			egg.party = enemy.party
			egg.damage = enemy.projectile_damage
			egg.room_bounds = enemy.room_bounds
			egg.travel_time = egg_travel_time
			egg.landing_radius = landing_radius
			egg.position = enemy.position
			egg.landing_position = locked_target
			var facing: float = -1.0 if direction.x < 0.0 else 1.0
			egg.release_offset = Vector2(SkuaIceEgg.RELEASE_OFFSET_RIGHT.x * facing, SkuaIceEgg.RELEASE_OFFSET_RIGHT.y)
			enemy.get_parent().add_child(egg)
			state = State.RECOVER
			remaining = shot_cooldown
		return Vector2.ZERO

	if state == State.RECOVER and remaining <= 0.0:
		state = State.POSITION

	var distance: float = enemy.global_position.distance_to(target.global_position)
	if state == State.POSITION and remaining <= 0.0 and distance <= attack_range:
		locked_target = target.global_position
		direction = enemy.global_position.direction_to(locked_target)
		state = State.WINDUP
		remaining = windup_time
		return Vector2.ZERO
	if distance < retreat_range:
		return target.global_position.direction_to(enemy.global_position) * enemy.speed
	if distance > preferred_range:
		return enemy.global_position.direction_to(target.global_position) * enemy.speed
	return Vector2.ZERO

func on_damage(event: DamageEvent) -> void:
	if event.impulse.length() >= 250.0 and state == State.WINDUP:
		state = State.RECOVER
		remaining = shot_cooldown

func cancel() -> void:
	state = State.POSITION
	remaining = 0.9
