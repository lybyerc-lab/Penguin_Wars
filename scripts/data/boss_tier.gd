class_name BossTier
extends Resource
## One rung of a boss ladder, counted in GLOBAL RUN WAVES — not cave numbers
## and not room-local wave numbers.
##
## Set exactly one of:
##   `at`    — this single wave carries this boss. Outranks any interval, so a
##             one-off variant can sit on a wave an interval would also claim.
##   `every` — every Nth wave carries it. Among intervals, the largest matching
##             one wins, so a 20 rung replaces the 10 and 5 rungs on wave 20
##             without any of them knowing about the others.

## A single run wave. 0 means unused.
@export_range(0, 9999) var at: int = 0
## Every Nth run wave. 0 means unused.
@export_range(0, 9999) var every: int = 0
@export var boss: BossDefinition

func is_exact() -> bool:
	return at > 0

func matches(run_wave: int) -> bool:
	if run_wave <= 0:
		return false
	if is_exact():
		return run_wave == at
	return every > 0 and run_wave % every == 0

## Higher wins. An exact wave outranks every interval.
func precedence() -> int:
	return 1_000_000 if is_exact() else every
