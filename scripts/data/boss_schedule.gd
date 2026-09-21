class_name BossSchedule
extends Resource
## Selection only: given a GLOBAL RUN WAVE, which boss belongs there.
##
## It counts run waves — not cave numbers, not room-local wave numbers. Wave 7
## means the seventh wave of the whole run, whichever room it happens in.
##
## It never spawns, places, scales or pays, and nothing calls it yet. Its
## eventual caller is Expedition, through a lightweight run/wave plan that
## describes the run and writes the answer into an EncounterDefinition;
## EncounterDirector takes it from there. The director must never ask this
## directly — that would put milestone rules inside the combat loop.
##
## Escalating difficulty across a long run is deliberately NOT here. That is
## what RunModifiers and EncounterDefinition.difficulty_multiplier are for, and
## it is where Storm difficulty will later alter or replace these encounters.

@export var id: StringName = &"milestones"
## Ladder rungs, in any order. Exact waves beat intervals; among intervals the
## largest matching one wins.
@export var tiers: Array[BossTier] = []

## Null when this run wave carries no boss.
func boss_for(run_wave: int) -> BossDefinition:
	var winner: BossTier = null
	for tier: BossTier in tiers:
		if tier == null or not tier.matches(run_wave):
			continue
		if winner == null or tier.precedence() > winner.precedence():
			winner = tier
	return winner.boss if winner != null else null

func is_milestone(run_wave: int) -> bool:
	return boss_for(run_wave) != null

## Every run wave carrying a boss, up to and including `final_wave`.
func milestones(final_wave: int) -> PackedInt32Array:
	var found := PackedInt32Array()
	for run_wave: int in range(1, maxi(0, final_wave) + 1):
		if is_milestone(run_wave):
			found.append(run_wave)
	return found

## Everything wrong with this schedule, so a broken ladder fails a test rather
## than a run. Empty means usable.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	var exact_seen := PackedInt32Array()
	var interval_seen := PackedInt32Array()
	for tier: BossTier in tiers:
		if tier == null:
			found.append("%s has an empty tier slot" % id)
			continue
		if tier.at > 0 and tier.every > 0:
			found.append("%s has a tier set to both wave %d and every %d" % [id, tier.at, tier.every])
		elif tier.at <= 0 and tier.every <= 0:
			found.append("%s has a tier with neither a wave nor an interval" % id)
		if tier.is_exact():
			if exact_seen.has(tier.at):
				found.append("%s has two tiers on wave %d" % [id, tier.at])
			exact_seen.append(tier.at)
		elif tier.every > 0:
			if interval_seen.has(tier.every):
				found.append("%s has two tiers at every %d" % [id, tier.every])
			interval_seen.append(tier.every)
		if tier.boss == null:
			found.append("%s has a tier that names no boss" % id)
		elif tier.boss.scene == null:
			found.append("%s boss '%s' has no scene" % [id, tier.boss.id])
	return found
