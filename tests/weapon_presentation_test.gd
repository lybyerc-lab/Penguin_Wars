extends SceneTree
## Mechanical coverage for stable multi-weapon presentation and timing identity.

var failures: int = 0
const LANCE: WeaponDefinition = preload("res://resources/weapons/ice_lance.tres")
const CLEAVER: WeaponDefinition = preload("res://resources/weapons/fish_cleaver.tres")

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var arena := load("res://scenes/arena/test_arena.tscn").instantiate() as Node2D
	root.add_child(arena)
	await process_frame
	var player: PenguinPlayer = arena.party.members()[0]
	var four: Array[WeaponDefinition] = [LANCE, LANCE, CLEAVER, CLEAVER]
	player.configure_weapon_loadout(four)
	var rack: WeaponRack = player.weapon_rack
	for slot: int in range(4):
		var controller: WeaponController = rack.controller_at(slot)
		check(controller.rack_slot == slot and controller.get_node("Visual") != null, "occupied slot %d owns stable controller and visual identity" % slot)
	check(rack.controller_at(0).presentation_origin(0.0) == rack.controller_at(3).presentation_origin(0.0), "combat effects now share the body-centred hand origin")
	check(rack.controller_at(0).firing_phase_delay() == 0.0 and rack.controller_at(1).firing_phase_delay() > 0.0 and rack.controller_at(1).firing_phase_delay() != rack.controller_at(2).firing_phase_delay(), "per-slot duplicate firing phases are deterministic and distinct")
	check(is_equal_approx(rack.controller_at(1).definition.cooldown, LANCE.cooldown), "stagger leaves sustained weapon cooldown definition-driven")
	var old_slot_one: WeaponController = rack.controller_at(1)
	rack.remove_weapon(1)
	await process_frame
	check(rack.is_slot_empty(1) and not is_instance_valid(old_slot_one), "clearing a slot removes only that controller and visual")
	player.configure_weapon_loadout(four)
	var changes: Array[WeaponMaturation] = rack.resolve_maturation_once()
	check(changes.size() == 2 and rack.controller_at(0).rack_slot == 0 and rack.controller_at(2).rack_slot == 2 and rack.is_slot_empty(1) and rack.is_slot_empty(3), "maturation preserves remaining visual slot identities and gaps")
	check(rack.controller_at(0).get_node("Visual") != rack.controller_at(2).get_node("Visual"), "matured remaining weapons keep separate presentation nodes")
	var six: Array[WeaponDefinition] = [LANCE, LANCE, LANCE, CLEAVER, CLEAVER, CLEAVER]
	player.configure_weapon_loadout(six)
	for slot: int in range(6):
		check(rack.controller_at(slot).get_node("Visual") != null, "six occupied slots retain separate visual ownership")
	arena.free()
	await process_frame
	var four_player := load("res://scenes/arena/test_arena.tscn").instantiate() as Node2D
	four_player.player_count = 4
	root.add_child(four_player)
	await process_frame
	var seen_controllers: Array[WeaponController] = []
	for member: PenguinPlayer in four_player.party.members():
		member.configure_weapon_loadout(four)
		var controller: WeaponController = member.weapon_rack.controller_at(1)
		check(not seen_controllers.has(controller) and controller.rack_slot == 1 and controller.firing_phase_delay() > 0.0, "each player owns independent controller and phase runtime")
		seen_controllers.append(controller)
	four_player.free()
	print("WEAPON PRESENTATION TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
