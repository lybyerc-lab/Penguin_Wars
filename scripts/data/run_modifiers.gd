class_name RunModifiers
extends Resource
## Whole-run dials: a difficulty level, a weekly-run rule, an accessibility
## handicap. The identity default changes nothing, so a run that names no
## modifiers behaves exactly as it did before this seam existed.
##
## These compose with, rather than replace, per-room difficulty:
## EncounterDefinition.difficulty_multiplier says how hard this room is
## relative to its neighbours; these say how hard the whole run is.
## EncounterDirector multiplies the two.

@export var id: StringName = &"standard"
@export var display_name: String = "Standard"
@export_range(0.1, 10.0) var enemy_health_scale: float = 1.0
@export_range(0.1, 10.0) var enemy_damage_scale: float = 1.0
## Applied before each player's own Harvest, so fractional carry still works.
@export_range(0.0, 10.0) var income_scale: float = 1.0
## Credited to every penguin when the party is created.
@export_range(0, 9999) var starting_snowflakes: int = 0

func is_identity() -> bool:
	return is_equal_approx(enemy_health_scale, 1.0) and is_equal_approx(enemy_damage_scale, 1.0) and is_equal_approx(income_scale, 1.0) and starting_snowflakes == 0
