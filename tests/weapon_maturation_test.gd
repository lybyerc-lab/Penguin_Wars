extends SceneTree
## Focused proof of the inventory-only, one-event maturation contract.

var failures: int = 0
const LANCE_I: WeaponDefinition = preload("res://resources/weapons/ice_lance.tres")
const LANCE_II: WeaponDefinition = preload("res://resources/weapons/ice_lance_ii.tres")
const LANCE_III: WeaponDefinition = preload("res://resources/weapons/ice_lance_iii.tres")
const LANCE_IV: WeaponDefinition = preload("res://resources/weapons/ice_lance_iv.tres")
const CLEAVER_I: WeaponDefinition = preload("res://resources/weapons/fish_cleaver.tres")
const CLEAVER_II: WeaponDefinition = preload("res://resources/weapons/fish_cleaver_ii.tres")

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _load(player: PenguinPlayer, definitions: Array[WeaponDefinition]) -> WeaponRack:
	player.configure_weapon_loadout(definitions)
	return player.weapon_rack

func _run() -> void:
	var arena := load("res://scenes/arena/test_arena.tscn").instantiate() as Node2D
	root.add_child(arena)
	await process_frame
	var players: Array[PenguinPlayer] = arena.party.members()
	var player: PenguinPlayer = players[0]
	var rack: WeaponRack = player.weapon_rack
	var changed_count := [0]
	var maturity_count := [0]
	var signaled_changes: Array[WeaponMaturation] = []
	rack.changed.connect(func() -> void: changed_count[0] += 1)
	rack.matured.connect(func(changes: Array[WeaponMaturation]) -> void:
		maturity_count[0] += 1
		signaled_changes.clear()
		signaled_changes.append_array(changes))

	# One clean event advances every compatible snapshot pair, preserving the
	# lower slot as the survivor and leaving holes in place.
	rack = _load(player, [LANCE_I, LANCE_I, CLEAVER_I, CLEAVER_I, LANCE_I, LANCE_I])
	var old_lance_controller: WeaponController = rack.controller_at(0)
	var signals_before: int = changed_count[0]
	var first: Array[WeaponMaturation] = rack.resolve_maturation_once()
	check(first.size() == 3 and maturity_count[0] == 1 and signaled_changes.size() == 3, "one event reports all independent matured pairs through the dedicated signal")
	check(changed_count[0] == signals_before + 1, "a non-empty maturation event emits changed exactly once")
	check(rack.weapon_at(0) == LANCE_II and rack.is_slot_empty(1) and rack.weapon_at(2) == CLEAVER_II and rack.is_slot_empty(3) and rack.weapon_at(4) == LANCE_II and rack.is_slot_empty(5), "all families resolve independently with no compaction")
	check(first[0].family_id == LANCE_I.family_id and first[0].keep_slot == 0 and first[0].consumed_slot == 1 and first[0].previous_definition == LANCE_I and first[0].resulting_definition == LANCE_II, "result data identifies family, slots, and immutable before/after definitions")
	check(rack.controller_at(0) != old_lance_controller and rack.controller_at(0).definition == LANCE_II, "the kept slot receives a fresh controller for its new definition")
	await process_frame
	check(not is_instance_valid(old_lance_controller), "the consumed previous controller is disposed after the replacement frame")

	# A definition created by this event is not allowed to consume another pair.
	rack = _load(player, [LANCE_I, LANCE_I, LANCE_II, LANCE_II])
	var cascade: Array[WeaponMaturation] = rack.resolve_maturation_once()
	check(cascade.size() == 2 and rack.weapon_at(0) == LANCE_II and rack.weapon_at(2) == LANCE_III and rack.is_slot_empty(1) and rack.is_slot_empty(3), "pre-event pairs resolve once while newly created Tier II cannot cascade")

	# Pair selection is deterministic per family/tier: lowest eligible slot wins
	# and then chooses the next lowest compatible slot, skipping holes and others.
	rack = _load(player, [LANCE_I, CLEAVER_I, LANCE_I, LANCE_I, CLEAVER_I, LANCE_I])
	var deterministic: Array[WeaponMaturation] = rack.resolve_maturation_once()
	check(deterministic.size() == 3 and deterministic[0].keep_slot == 0 and deterministic[0].consumed_slot == 2 and deterministic[1].keep_slot == 1 and deterministic[1].consumed_slot == 4 and deterministic[2].keep_slot == 3 and deterministic[2].consumed_slot == 5, "selection is lowest-slot deterministic for interleaved families")

	# Nulls, mismatched tiers/families, Tier IV and an absent next tier never move.
	rack = _load(player, [LANCE_IV, LANCE_IV, LANCE_I, LANCE_II, CLEAVER_I])
	var before_noop: Array[WeaponDefinition] = rack.slots()
	var matured_before_noop: int = maturity_count[0]
	var changed_before_noop: int = changed_count[0]
	check(rack.resolve_maturation_once().is_empty() and rack.slots() == before_noop, "invalid or incomplete pairs are a true no-op")
	check(maturity_count[0] == matured_before_noop and changed_count[0] == changed_before_noop, "no-op maturation does not emit changed or matured")

	# All resources remain shared immutable data, and player racks remain isolated.
	var lance_damage: float = LANCE_I.damage
	check(LANCE_I.next_tier == LANCE_II and LANCE_I.damage == lance_damage, "maturation never mutates source definition resources")
	var second_rack: WeaponRack = _load(players[1], [CLEAVER_I, CLEAVER_I])
	check(second_rack.resolve_maturation_once().size() == 1 and second_rack.weapon_at(0) == CLEAVER_II and rack.weapon_at(0) == LANCE_IV, "each player owns an independent maturation result")

	# A downed registered player is still inventory-bearing, and a fresh loadout
	# resets exactly as a new run does.
	players[1].health.take_damage(DamageEvent.new(1000.0))
	second_rack = _load(players[1], [LANCE_I, LANCE_I])
	check(not players[1].health.is_alive() and second_rack.resolve_maturation_once().size() == 1 and second_rack.weapon_at(0) == LANCE_II, "a downed registered player rack can mature")
	_load(player, [LANCE_I])
	check(player.weapon_rack.weapon_at(0) == LANCE_I and player.weapon_rack.occupied_count() == 1, "fresh loadout initialization restores a clean starter rack")

	# Ordinary encounters own no policy connection to this inventory operation.
	player.configure_weapon_loadout([LANCE_I, LANCE_I])
	arena.encounter.wave_cleared.emit(5)
	await process_frame
	check(player.weapon_rack.weapon_at(0) == LANCE_I and player.weapon_rack.weapon_at(1) == LANCE_I, "normal arena wave completion does not automatically mature weapons")
	arena.free()
	print("WEAPON MATURATION TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
