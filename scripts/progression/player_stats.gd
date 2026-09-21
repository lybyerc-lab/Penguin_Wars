class_name PlayerStats
extends Resource
## A fresh instance per player/run. Future skills can modify stats through this seam.
@export var harvest_multiplier: float = 1.0
@export var armor: float = 0.0
@export var regeneration: float = 0.0
@export var damage_percent: float = 0.0
@export var melee_damage: float = 0.0
@export var ranged_damage: float = 0.0
@export var attack_speed: float = 0.0
@export var critical_chance: float = 0.0
@export var dodge_chance: float = 0.0
@export var pickup_bonus: float = 0.0
@export var engineering: float = 0.0
@export var range_bonus: float = 0.0
var income_fraction: float = 0.0

func weapon_damage(base: float, melee: bool, roll: float) -> float:
	var flat: float = melee_damage if melee else ranged_damage
	var result: float = maxf(1.0, (base + flat) * maxf(0.1, 1.0 + damage_percent / 100.0))
	return result * 1.5 if roll < clampf(critical_chance / 100.0, 0.0, 1.0) else result

func cooldown(base: float) -> float:
	return maxf(0.08, base / maxf(0.2, 1.0 + attack_speed / 100.0))

func damage_received(base: float, roll: float) -> float:
	if roll < clampf(dodge_chance / 100.0, 0.0, 0.6):
		return 0.0
	return base * 100.0 / (100.0 + maxf(0.0, armor) * 5.0)

## external_scale is the run's income dial; it is applied before Harvest so a
## fractional result is still carried forward rather than rounded away.
func harvest_yield(base_amount: int, external_scale: float = 1.0) -> int:
	if base_amount <= 0 or external_scale <= 0.0:
		return 0
	var total: float = base_amount * harvest_multiplier * external_scale + income_fraction
	var payout: int = floori(total)
	income_fraction = total - payout
	return payout
