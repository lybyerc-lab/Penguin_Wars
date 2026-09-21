class_name HitFeedback
extends Node
## Visual-only health listener; never changes combat state.
var _actor: Node2D
var _flash: float = 0.0

func _ready() -> void:
	_actor = get_parent() as Node2D
	(_actor.get_node("Health") as Health).damaged.connect(_on_damaged)

func _on_damaged(event: DamageEvent) -> void:
	_flash = 0.11
	_actor.modulate = Color(2.5, 2.5, 2.5)
	var effect := HitEffect.new()
	effect.position = _actor.position
	effect.amount = event.amount
	effect.lethal = not (_actor.get_node("Health") as Health).is_alive()
	if _actor is PenguinPlayer:
		effect.tint = Color("ff8792")
	_actor.get_parent().add_child(effect)

func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			_actor.modulate = Color.WHITE
