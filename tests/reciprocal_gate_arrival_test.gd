extends SceneTree
## Physical regression for held movement across a reciprocal room doorway.

var failures: int = 0

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

func _stand_party(run: Node2D, position: Vector2) -> void:
	for player: PenguinPlayer in run.party.members(true):
		player.global_position = position

func _run() -> void:
	var run := load("res://scenes/prototypes/phase_a_expedition_review.tscn").instantiate() as Node2D
	root.add_child(run)
	await process_frame

	var pass_gate := _gate_to(run, &"frozen_coast_pass_phase_a")
	check(pass_gate != null, "Township exposes the Frozen Coast Pass gate")
	if pass_gate != null:
		_stand_party(run, pass_gate.global_position)
		pass_gate._physics_process(PartyGate.DWELL + 0.1)
		await process_frame

	check(run.room != null and run.room.id == &"frozen_coast_pass_phase_a",
		"physical Township doorway travel enters Frozen Coast Pass")
	var home_gate := _gate_to(run, &"")
	check(home_gate != null, "Frozen Coast Pass exposes its reciprocal Township gate")
	if home_gate != null:
		check(home_gate.arrival_protected, "reciprocal gate starts arrival-protected")
		check(home_gate.arrival_area().has_point(run.party.members(true)[0].global_position - home_gate.global_position),
			"authored Pass arrival is covered by the reciprocal arrival area")

		# Continue toward the return threshold as if the departure input is still held.
		_stand_party(run, home_gate.global_position)
		home_gate._physics_process(PartyGate.DWELL + 0.1)
		check(run.room != null and run.room.id == &"frozen_coast_pass_phase_a",
			"held movement after arrival cannot immediately return to Township")
		check(home_gate.dwell == 0.0 and not home_gate.spent,
			"arrival protection accumulates no return dwell")

		# Clear the expanded arrival area inward, then return and dwell normally.
		var clear_position := home_gate.global_position + Vector2(0.0,
			-PartyGate.THRESHOLD_DEPTH - PartyGate.ARRIVAL_CLEARANCE - 20.0)
		_stand_party(run, clear_position)
		home_gate._physics_process(0.016)
		check(not home_gate.arrival_protected,
			"reciprocal gate arms after the whole living party clearly leaves its arrival area")

		_stand_party(run, home_gate.global_position)
		home_gate._physics_process(PartyGate.DWELL + 0.1)
		await process_frame

	check(run.room != null and run.room.kind == RoomDefinition.Kind.TOWN,
		"clearing and revisiting the reciprocal gate returns to Township normally")

	run.free()
	print("RECIPROCAL GATE ARRIVAL TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
