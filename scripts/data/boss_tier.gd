class_name BossTier
extends Resource
## One rung of a boss ladder: which boss belongs at every Nth milestone.
## A larger `every` outranks a smaller one, so a 20 tier replaces the 10 and 5
## tiers on milestone 20 without any of them knowing about the others.

@export_range(1, 999) var every: int = 5
@export var boss: BossDefinition
