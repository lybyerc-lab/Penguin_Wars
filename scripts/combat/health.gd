class_name Health
extends Node

signal changed(current: float, maximum: float)
signal died(event: DamageEvent)
signal damaged(event: DamageEvent)

@export_range(1.0, 10000.0) var maximum: float = 100.0
var current: float
var invulnerable: bool = false

func _ready() -> void:
	current = maximum

func is_alive() -> bool:
	return current > 0.0

func take_damage(event: DamageEvent) -> void:
	if not is_alive() or invulnerable or event.amount <= 0.0:
		return
	current = maxf(0.0, current - event.amount)
	changed.emit(current, maximum)
	damaged.emit(event)
	if not is_alive():
		died.emit(event)

func heal(amount: float) -> void:
	if not is_alive() or amount <= 0.0:
		return
	current = minf(maximum, current + amount)
	changed.emit(current, maximum)
