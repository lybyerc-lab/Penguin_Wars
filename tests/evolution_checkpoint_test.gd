extends SceneTree
## Prototype timing coverage. Inventory mechanics are separately tested.

var failures: int = 0
const LANCE_I: WeaponDefinition = preload("res://resources/weapons/ice_lance.tres")
const LANCE_II: WeaponDefinition = preload("res://resources/weapons/ice_lance_ii.tres")
const CLEAVER_I: WeaponDefinition = preload("res://resources/weapons/fish_cleaver.tres")
const CLEAVER_II: WeaponDefinition = preload("res://resources/weapons/fish_cleaver_ii.tres")

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var prototype := load("res://scenes/prototypes/evolution_checkpoint.tscn").instantiate() as Node2D
	root.add_child(prototype)
	await process_frame
	var player: PenguinPlayer = prototype.party.members()[0]
	var rack: WeaponRack = player.weapon_rack
	check(prototype.party.members().size() == 1 and prototype.encounter.definition.wave_count == 6, "checkpoint scene is a dedicated one-player six-wave encounter (%d players, %d waves)" % [prototype.party.members().size(), prototype.encounter.definition.wave_count])
	check(rack.slots().slice(0, 4) == [LANCE_I, LANCE_I, CLEAVER_I, CLEAVER_I], "prototype starts with the specified four-slot Tier I build")
	for wave: int in [1, 2, 3, 4]:
		prototype.encounter.wave_cleared.emit(wave)
	check(not prototype.checkpoint_resolved() and rack.weapon_at(0) == LANCE_I, "waves one through four do not trigger evolution")
	prototype.encounter.wave_cleared.emit(5)
	check(prototype.checkpoint_resolved() and prototype.last_changes().size() == 2, "wave five resolves the checkpoint exactly once")
	check(rack.weapon_at(0) == LANCE_II and rack.is_slot_empty(1) and rack.weapon_at(2) == CLEAVER_II and rack.is_slot_empty(3), "wave five produces the expected evolved wave-six loadout")
	check(prototype.checkpoint_notice_visible() and "EVOLUTION CHECKPOINT" in prototype.checkpoint_presentation_text(), "intermission presents a compact evolution summary without input")
	prototype.encounter.wave_cleared.emit(5)
	check(prototype.last_changes().size() == 2 and rack.weapon_at(0) == LANCE_II, "duplicate wave-five signals cannot repeat or cascade the checkpoint")
	prototype.encounter.state = EncounterDirector.State.INTERMISSION
	prototype.encounter.wave = 5
	prototype.progression.toggle_ready(1)
	check(prototype.encounter.wave == 6 and rack.weapon_at(0) == LANCE_II, "normal F-ready flow reaches wave six with the evolved rack intact")
	await process_frame
	check(not prototype.checkpoint_notice_visible(), "checkpoint summary clears when wave six begins")
	prototype.free()
	await process_frame

	# The exact prototype policy applies to every registered member, including a
	# downed member, while the four personal racks remain separate runtimes.
	prototype = load("res://scenes/prototypes/evolution_checkpoint.tscn").instantiate() as Node2D
	prototype.player_count = 4
	root.add_child(prototype)
	await process_frame
	var four_loadout: Array[WeaponDefinition] = [LANCE_I, LANCE_I]
	var racks: Array[WeaponRack] = []
	for member: PenguinPlayer in prototype.party.members():
		member.configure_weapon_loadout(four_loadout)
		racks.append(member.weapon_rack)
	prototype.party.members()[2].health.take_damage(DamageEvent.new(1000.0))
	prototype.encounter.wave_cleared.emit(5)
	var all_matured := true
	for member: PenguinPlayer in prototype.party.members():
		all_matured = all_matured and member.weapon_rack.weapon_at(0) == LANCE_II and member.weapon_rack.is_slot_empty(1)
	check(racks.size() == 4 and racks[0] != racks[1] and racks[1] != racks[2] and all_matured, "wave five matures all four independent racks, including a downed registered player")
	prototype.free()
	await process_frame

	# A valid checkpoint with no pair produces no false evolution presentation.
	prototype = load("res://scenes/prototypes/evolution_checkpoint.tscn").instantiate() as Node2D
	root.add_child(prototype)
	await process_frame
	var no_pair: Array[WeaponDefinition] = [LANCE_I, CLEAVER_I]
	prototype.party.members()[0].configure_weapon_loadout(no_pair)
	prototype.encounter.wave_cleared.emit(5)
	check(prototype.checkpoint_resolved() and prototype.last_changes().is_empty() and not prototype.checkpoint_notice_visible(), "a no-pair checkpoint is guarded but presents no false maturity")
	prototype.free()
	print("EVOLUTION CHECKPOINT TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
