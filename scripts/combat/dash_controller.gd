class_name DashController
extends Node
## Per-player burst state. The player owns movement and applies invulnerability.
@export var duration: float = 0.16
@export var cooldown: float = 1.1
@export var burst_speed: float = 680.0
var remaining: float = 0.0
var cooldown_remaining: float = 0.0
var direction := Vector2.DOWN
var facing := Vector2.DOWN

func tick(delta: float, movement: Vector2, requested: bool, alive: bool) -> void:
	remaining = maxf(0.0, remaining - delta)
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	if not alive:
		remaining = 0.0
		return
	if movement.length_squared() > 0.01:
		facing = movement.normalized()
	if requested and cooldown_remaining <= 0.0:
		direction = facing
		remaining = duration
		cooldown_remaining = cooldown

func is_active() -> bool:
	return remaining > 0.0
