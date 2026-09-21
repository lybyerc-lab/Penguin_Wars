class_name BossSchedule
extends Resource
## Selection only: given a milestone index, which boss belongs there.
##
## It never spawns, places, scales or pays anything. Whoever builds a run's
## encounters asks for a boss and writes the answer into an
## EncounterDefinition; EncounterDirector takes it from there. That keeps the
## director free of milestone rules and keeps this free of combat.
##
## Escalating difficulty across a long run is deliberately NOT here: that is
## what RunModifiers and EncounterDefinition.difficulty_multiplier are for.

@export var id: StringName = &"milestones"
## Ladder rungs, in any order. The rung with the largest matching `every` wins.
@export var tiers: Array[BossTier] = []

## Null when this index carries no boss.
func boss_for(index: int) -> BossDefinition:
	var winner: BossTier = null
	if index <= 0:
		return null
	for tier: BossTier in tiers:
		if tier == null or tier.every <= 0 or index % tier.every != 0:
			continue
		if winner == null or tier.every > winner.every:
			winner = tier
	return winner.boss if winner != null else null

func is_milestone(index: int) -> bool:
	return boss_for(index) != null

## Every milestone index carrying a boss, up to and including `last`.
func milestones(last: int) -> PackedInt32Array:
	var found := PackedInt32Array()
	for index: int in range(1, maxi(0, last) + 1):
		if is_milestone(index):
			found.append(index)
	return found

## Everything wrong with this schedule, so a broken ladder fails a test rather
## than a run. Empty means usable.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	var seen := PackedInt32Array()
	for tier: BossTier in tiers:
		if tier == null:
			found.append("%s has an empty tier slot" % id)
			continue
		if tier.every <= 0:
			found.append("%s has a tier with a non-positive interval" % id)
		if seen.has(tier.every):
			found.append("%s has two tiers at every %d" % [id, tier.every])
		seen.append(tier.every)
		if tier.boss == null:
			found.append("%s tier every %d names no boss" % [id, tier.every])
		elif tier.boss.scene == null:
			found.append("%s boss '%s' has no scene" % [id, tier.boss.id])
	return found
