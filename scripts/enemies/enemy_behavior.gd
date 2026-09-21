class_name EnemyBehavior
extends Node
## Movement/attack strategy. Shared actor retains health, knockback and rewards.
func movement(enemy: ArenaEnemy, target: PenguinPlayer, _delta: float) -> Vector2:
	return enemy.global_position.direction_to(target.global_position) * enemy.speed

func contact_enabled() -> bool:
	return true

func on_damage(_event: DamageEvent) -> void:
	pass

func cancel() -> void:
	pass
