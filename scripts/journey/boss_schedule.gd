class_name BossSchedule
extends RefCounted
## Higher milestones replace the five-cave mini-boss slot.
static func for_cave(number: int) -> BossDefinition:
	if number <= 0 or number % 5 != 0:
		return null
	if number % 20 == 0:
		return preload("res://resources/bosses/mondo.tres")
	if number % 10 == 0:
		return preload("res://resources/bosses/warden.tres")
	return preload("res://resources/bosses/mini.tres")

static func difficulty(number: int) -> float:
	return 1.0 + 0.35 * floorf(float(maxi(1, number) - 1) / 20.0)
