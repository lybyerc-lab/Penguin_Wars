class_name BossActor
extends ArenaEnemy
## Contract for the optional boss phase. A boss is an ordinary enemy: it takes
## damage, drops loot and dies through the same interfaces, so nothing in
## combat needs to know it is special.
##
## EncounterDirector guarantees, in this order:
##   1. `party` is set.
##   2. `configure()` is called while the node is still out of the tree, so a
##      Health.maximum written there becomes the starting health.
##   3. Run and room scaling are applied on top, identically to every other
##      enemy in the room.
##   4. `arena_bounds` is set from the room, inset by `hit_radius`.
##   5. The node is placed at the corner furthest from the living party and
##      added to the actor root.
##
## Subclasses own everything about how a boss fights: attacks, telegraphs,
## art and any extra BossDefinition fields they need. Attach an EnemyBehavior
## child named "Behavior" as the charger and thrower scenes do; the shared
## enemy actor already drives it.

var boss_definition: BossDefinition

## Default: take health from the definition and scale it by party size. Override
## to add body size, resistance, collision shape and behavior, and call super()
## unless the subclass sets its own health.
func configure(definition: BossDefinition, party_size: int) -> void:
	boss_definition = definition
	if definition == null:
		return
	var scaling: float = 1.0 + definition.party_health_scaling * maxi(0, party_size - 1)
	get_node("Health").maximum = definition.maximum_health * scaling

## Name the boss bar should show. Override if a subclass renames itself in play.
func title() -> String:
	return boss_definition.display_name if boss_definition != null else "Boss"
