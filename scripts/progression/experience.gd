class_name Experience
extends Node

signal changed(level: int, xp: int, required: int)
signal leveled_up(level: int)

var level: int = 1
var xp: int = 0

func required_xp() -> int:
	return 5 + (level - 1) * 3

func grant(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	while xp >= required_xp():
		xp -= required_xp()
		level += 1
		leveled_up.emit(level)
	changed.emit(level, xp, required_xp())
