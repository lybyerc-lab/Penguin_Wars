class_name DamageEvent
extends RefCounted
## Transient combat message. Source ID is a party ID, never a network peer ID.
var amount: float
var source_player_id: int
var impulse := Vector2.ZERO

func _init(value: float = 0.0, source_id: int = 0, push: Vector2 = Vector2.ZERO) -> void:
	amount = value
	source_player_id = source_id
	impulse = push
