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
##   3. Room difficulty and the run's RunModifiers are applied on top,
##      identically to every other enemy in the room. Do not apply them here.
##   4. `room_bounds` is set to the room rect and `arena_bounds` to that rect
##      inset by `hit_radius`, so a large body cannot overhang the wall while
##      its projectiles still belong to the whole room.
##   5. The node is placed at the corner furthest from the living party and
##      added to the actor root.
##
## Subclasses own everything about how a boss fights: attacks, telegraphs and
## art. Attach an EnemyBehavior child named "Behavior" as the charger and
## thrower scenes do; the shared enemy actor already drives it.

## Emit when title() or phase() would render differently, so a boss bar can
## follow phase and enrage changes without polling for them.
signal presentation_changed

var boss_definition: BossDefinition

## Default: take base health and damage from the definition, with party-size
## scaling applied. Override to add body size, resistance, collision shape and
## behavior, and call super() unless the subclass sets its own health.
##
## Everything set here is a BASE value. The director scales it afterwards.
func configure(definition: BossDefinition, party_size: int) -> void:
	boss_definition = definition
	if definition == null:
		return
	get_node("Health").maximum = definition.scaled_health(party_size)
	contact_damage = definition.damage
	projectile_damage = definition.damage

## Name a boss bar should show.
func title() -> String:
	return boss_definition.display_name if boss_definition != null else "Boss"

## Short state a boss bar may append, such as "ENRAGED". Empty by default.
func phase() -> String:
	return ""

## Call after changing anything title() or phase() reports.
func announce() -> void:
	presentation_changed.emit()
