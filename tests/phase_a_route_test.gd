extends SceneTree
## Focused architecture proof for the Phase A outdoor journey. The review route
## uses existing Expedition + RoomDefinition + EncounterDefinition seams only.

var failures: int = 0
const REVIEW_REGION: RegionDefinition = preload("res://resources/regions/kelphollow_phase_a_review.tres")

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _gate_to(run: Node2D, target: StringName) -> PartyGate:
	for gate: PartyGate in run.gates():
		if gate.exit != null and gate.exit.target_id == target:
			return gate
	return null

func _run() -> void:
	check(REVIEW_REGION.problems().is_empty(), "Phase A review region validates")
	check(REVIEW_REGION.has_expedition(), "Kelphollow review region has an outdoor expedition entry")
	check(REVIEW_REGION.expedition_room(&"frozen_coast_pass_phase_a") != null, "Pass resolves through RegionDefinition")
	check(REVIEW_REGION.expedition_room(&"driftfield_phase_a") != null, "Driftfield resolves through RegionDefinition")

	var run := load("res://scenes/prototypes/phase_a_expedition_review.tscn").instantiate() as Node2D
	root.add_child(run)
	await process_frame

	check(run.room != null and run.room.id == &"kelphollow", "review scene still begins in the real Township")
	check(run.cave == null, "outdoor expedition begins outside cave state")
	var player: PenguinPlayer = run.party.members()[0]
	check(player.weapon_rack.occupied_count() == 3, "Phase A review penguin starts with exactly three test weapons")
	check(player.weapon_rack.weapon_at(0).id == &"fish_spear", "review slot 1 is Fish Spear")
	check(player.weapon_rack.weapon_at(1).id == &"icicle_slingshot", "review slot 2 is Icicle Slingshot")
	check(player.weapon_rack.weapon_at(2).id == &"snowbomb", "review slot 3 is Snowbomb")

	var pass_gate := _gate_to(run, &"frozen_coast_pass_phase_a")
	check(pass_gate != null and not pass_gate.locked, "Township Departure Gate points to the Frozen Coast Pass")
	if pass_gate != null:
		run._on_gate_travelled(pass_gate)
		await process_frame
	check(run.room != null and run.room.id == &"frozen_coast_pass_phase_a", "Expedition owns Township -> Pass travel")
	check(run.cave == null, "Pass does not masquerade as a cave")
	check(run.encounter.state == EncounterDirector.State.READY, "Pass stays exploration-only")

	var drift_gate := _gate_to(run, &"driftfield_phase_a")
	check(drift_gate != null and not drift_gate.locked, "Pass exposes the onward Driftfield gate")
	if drift_gate != null:
		run._on_gate_travelled(drift_gate)
		await process_frame
	check(run.room != null and run.room.id == &"driftfield_phase_a", "Expedition owns Pass -> Driftfield travel")
	check(run.encounter.definition != null and run.encounter.definition.resource_path.ends_with("driftfield_phase_a.tres"), "Driftfield owns the Phase A encounter")
	check(run.encounter.state == EncounterDirector.State.SPAWNING, "Driftfield combat starts on entry")

	var back_gate := _gate_to(run, &"frozen_coast_pass_phase_a")
	check(back_gate != null and back_gate.locked, "combat locks the return route until Driftfield is clear")
	run._on_room_cleared()
	check(back_gate != null and not back_gate.locked, "clearing Driftfield re-opens the return route")
	if back_gate != null:
		run._on_gate_travelled(back_gate)
		await process_frame
	check(run.room != null and run.room.id == &"frozen_coast_pass_phase_a", "Driftfield returns through the same Pass")

	var home_gate := _gate_to(run, &"")
	check(home_gate != null, "Pass has an explicit return-to-town exit")
	if home_gate != null:
		run._on_gate_travelled(home_gate)
		await process_frame
	check(run.room != null and run.room.kind == RoomDefinition.Kind.TOWN, "outdoor route returns to Township without cave bookkeeping")

	run.free()
	print("PHASE A ROUTE TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
