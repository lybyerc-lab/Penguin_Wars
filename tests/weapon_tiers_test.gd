extends SceneTree
## Tier-chain, class aggregation and rack-merge coverage against real players.
var failures: int = 0
const LANCE_I: WeaponDefinition = preload("res://resources/weapons/ice_lance.tres")
const LANCE_II: WeaponDefinition = preload("res://resources/weapons/ice_lance_ii.tres")
const LANCE_III: WeaponDefinition = preload("res://resources/weapons/ice_lance_iii.tres")
const LANCE_IV: WeaponDefinition = preload("res://resources/weapons/ice_lance_iv.tres")
const CLEAVER_I: WeaponDefinition = preload("res://resources/weapons/fish_cleaver.tres")
const CLEAVER_II: WeaponDefinition = preload("res://resources/weapons/fish_cleaver_ii.tres")
const CLEAVER_III: WeaponDefinition = preload("res://resources/weapons/fish_cleaver_iii.tres")
const CLEAVER_IV: WeaponDefinition = preload("res://resources/weapons/fish_cleaver_iv.tres")

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	# Tier I tuning is preserved; upper values are provisional data, not runtime state.
	check(LANCE_I.damage == 14.0 and LANCE_I.cooldown == 0.42 and LANCE_I.reach == 240.0, "Ice Lance I retains current tuning")
	check(CLEAVER_I.damage == 22.0 and CLEAVER_I.cooldown == 1.05 and CLEAVER_I.reach == 105.0 and CLEAVER_I.pattern == WeaponDefinition.Pattern.ARC, "Fish Cleaver I retains current tuning")
	check(LANCE_II.damage / LANCE_II.cooldown >= 2.0 * LANCE_I.damage / LANCE_I.cooldown, "Ice Lance II conserves the simple damage-per-cooldown value of its two Tier I inputs")
	check(CLEAVER_II.damage / CLEAVER_II.cooldown >= 2.0 * CLEAVER_I.damage / CLEAVER_I.cooldown, "Fish Cleaver II conserves the simple damage-per-cooldown value of its two Tier I inputs")
	check(LANCE_I.damage < LANCE_II.damage and LANCE_II.damage < LANCE_III.damage and LANCE_III.damage < LANCE_IV.damage, "Ice Lance provisional tier damage remains strictly increasing")
	check(CLEAVER_I.damage < CLEAVER_II.damage and CLEAVER_II.damage < CLEAVER_III.damage and CLEAVER_III.damage < CLEAVER_IV.damage, "Fish Cleaver provisional tier damage remains strictly increasing")
	check(LANCE_I.next_tier == LANCE_II and LANCE_II.next_tier == LANCE_III and LANCE_III.next_tier == LANCE_IV and LANCE_IV.next_tier == null, "Ice Lance chain resolves I through IV")
	check(CLEAVER_I.next_tier == CLEAVER_II and CLEAVER_II.next_tier == CLEAVER_III and CLEAVER_III.next_tier == CLEAVER_IV and CLEAVER_IV.next_tier == null, "Fish Cleaver chain resolves I through IV")
	for definition: WeaponDefinition in [LANCE_I, LANCE_II, LANCE_III, LANCE_IV, CLEAVER_I, CLEAVER_II, CLEAVER_III, CLEAVER_IV]:
		check(definition.problems().is_empty(), "tier definition '%s' validates" % definition.id)
	check(LANCE_I.classes == [WeaponClasses.ICE, WeaponClasses.PRECISION] and CLEAVER_I.classes == [WeaponClasses.FISH, WeaponClasses.BLADE], "production class tags are canonical")

	var arena := load("res://scenes/arena/test_arena.tscn").instantiate() as Node2D
	root.add_child(arena)
	await process_frame
	var players: Array[PenguinPlayer] = arena.party.members()
	var rack: WeaponRack = players[0].weapon_rack
	var changed_count := [0]
	rack.changed.connect(func() -> void: changed_count[0] += 1)
	check(rack.add_weapon(LANCE_I) == 1, "duplicate Tier I enters an empty slot")
	var old_controller: WeaponController = rack.controller_at(0)
	check(rack.can_merge_slots(0, 1) and rack.merge_slots(0, 1), "same-family Tier I slots merge")
	check(rack.weapon_at(0) == LANCE_II and rack.is_slot_empty(1), "merge upgrades keep slot and consumes exactly one")
	check(rack.controller_at(0) != old_controller and rack.controller_at(0).definition == LANCE_II, "merge gives the kept slot a fresh controller")
	check(rack.add_weapon(LANCE_II) == 1 and rack.merge_slots(0, 1) and rack.weapon_at(0) == LANCE_III, "two Tier II merge to Tier III")
	check(rack.add_weapon(LANCE_III) == 1 and rack.merge_slots(0, 1) and rack.weapon_at(0) == LANCE_IV, "two Tier III merge to Tier IV")
	check(not rack.can_merge_slots(0, 0) and not rack.merge_slots(0, 1), "invalid and Tier IV merges leave the rack unchanged")
	check(rack.add_weapon(CLEAVER_I) == 1 and not rack.can_merge_slots(0, 1), "different families cannot merge")
	check(rack.class_count(WeaponClasses.ICE) == 1 and rack.class_count(WeaponClasses.PRECISION) == 1 and rack.class_count(WeaponClasses.FISH) == 1 and rack.class_count(WeaponClasses.BLADE) == 1, "class counts use occupied weapons, not tier values")
	check(rack.remove_weapon(1) == CLEAVER_I and not rack.has_class(WeaponClasses.FISH), "class counts update on removal")
	for slot: int in range(1, rack.capacity()):
		if rack.is_slot_empty(slot):
			rack.insert_weapon(slot, LANCE_I)
	check(rack.first_empty_slot() == -1 and rack.find_merge_slot(LANCE_I) == 1, "full rack exposes an incoming merge target")
	check(rack.merge_definition_into_slot(1, LANCE_I) and rack.weapon_at(1) == LANCE_II, "incoming compatible definition merges without a seventh slot")
	check(changed_count[0] > 0, "successful rack mutations emit changed")

	# Sharp Ice and Hone are player-wide, including weapons obtained afterwards.
	var sharp: UpgradeDefinition = load("res://resources/upgrades/sharp_ice.tres")
	players[0].apply_upgrade(sharp)
	check(players[0].stats.flat_weapon_damage == 3.0, "Sharp Ice writes player-wide flat damage")
	var base_damage := rack.controller_at(0).definition.damage + players[0].stats.flat_weapon_damage
	check(is_equal_approx(base_damage, LANCE_IV.damage + 3.0), "existing weapons read player-wide flat damage")
	rack.remove_weapon(5)
	rack.insert_weapon(5, CLEAVER_I)
	check(is_equal_approx(rack.controller_at(5).definition.damage + players[0].stats.flat_weapon_damage, CLEAVER_I.damage + 3.0), "new weapons inherit player-wide flat damage")
	check(players[1].stats.flat_weapon_damage == 0.0 and players[1].weapon_rack != rack, "player racks and damage stats remain independent")
	var signals_before_clear: int = changed_count[0]
	rack.clear()
	check(changed_count[0] == signals_before_clear + 1 and rack.occupied_count() == 0, "clear emits changed after removing a rack")
	arena.free()
	print("WEAPON TIERS TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
