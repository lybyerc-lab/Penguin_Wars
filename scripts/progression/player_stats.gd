class_name PlayerStats
extends Resource
## A fresh instance per player/run. Future skills can modify stats through this seam.
@export var harvest_multiplier: float = 1.0
var income_fraction: float = 0.0

func harvest_yield(base_amount: int) -> int:
	if base_amount <= 0:
		return 0
	var total: float = base_amount * harvest_multiplier + income_fraction
	var payout: int = floori(total)
	income_fraction = total - payout
	return payout
