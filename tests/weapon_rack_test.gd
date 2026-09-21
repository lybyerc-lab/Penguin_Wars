extends SceneTree
## Focused regression coverage for the personal six-slot weapon runtime.
var failures: int = 0

const LANCE: WeaponDefinition = preload("res://resources/weapons/ice_lance.tres")
const CLEAVER: WeaponDefinition = preload("res://resources/weapons/fish_cleaver.tres")

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _disable_combat(players: Array[PenguinPlayer]) -> void:
	for player: PenguinPlayer in players:
		player.set_physics_process(false)
		for slot: int in range(player.weapon_rack.capacity()):
			var controller := player.weapon_rack.controller_at(slot)
			if controller != null:
				controller.set_physics_process(false)

## Stand all living penguins on a gate long enough to use it.
func _travel(run: Node2D, gate: PartyGate) -> void:
	for player: PenguinPlayer in run.party.members(true):
		player.position = gate.position
	gate._physics_process(PartyGate.DWELL + 0.2)

func _run() -> void:
	var arena_scene: PackedScene = load("res://scenes/arena/test_arena.tscn")
	var arena := arena_scene.instantiate() as Node2D
	root.add_child(arena)
	await process_frame
	var players: Array[PenguinPlayer] = arena.party.members()
	_disable_combat(players)
	var rack: WeaponRack = players[0].weapon_rack
	var other_rack: WeaponRack = players[1].weapon_rack

	# Standard two-player spawn: one starting weapon in slot 0, five explicit
	# empty slots, and the old player.weapon view still points at slot 0.
	check(rack.capacity() == WeaponRack.DEFAULT_CAPACITY, "ordinary penguins receive six rack slots")
	check(rack.occupied_count() == 1 and rack.weapon_at(0) == LANCE, "Skua starts with Ice Lance in slot 0")
	check(players[0].weapon == rack.controller_at(0), "legacy slot-0 weapon access resolves through the rack")
	for slot: int in range(1, WeaponRack.DEFAULT_CAPACITY):
		check(rack.is_slot_empty(slot), "new rack slot %d starts empty" % (slot + 1))
	check(rack.first_empty_slot() == 1, "first empty slot follows the starter weapon")
	check(other_rack.occupied_count() == 1 and other_rack.weapon_at(0) == CLEAVER, "P2 owns an independent starting rack")
	check(rack.controller_at(0) != other_rack.controller_at(0), "players never share weapon controllers")

	# Core ownership API: fill, reject invalid use, replace, remove and clear.
	check(rack.add_weapon(null) == -1, "a null weapon cannot occupy a slot")
	check(rack.add_weapon(CLEAVER) == 1, "add_weapon uses the first empty slot")
	var second: WeaponController = rack.controller_at(1)
	check(second != null and second.definition == CLEAVER, "an occupied slot owns its controller")
	check(not rack.insert_weapon(1, LANCE), "insert never overwrites an occupied slot")
	check(not rack.insert_weapon(6, LANCE), "insert rejects an invalid slot")
	check(rack.replace_weapon(2, LANCE), "replace can fill an empty valid slot")
	check(rack.weapon_at(0) == LANCE and rack.weapon_at(1) == CLEAVER, "replace leaves unrelated slots intact")
	check(rack.remove_weapon(2) == LANCE and rack.is_slot_empty(2), "remove returns and clears the selected definition")
	check(rack.remove_weapon(9) == null and not rack.replace_weapon(-1, LANCE), "invalid remove and replace are rejected")
	for slot: int in range(2, WeaponRack.DEFAULT_CAPACITY):
		check(rack.add_weapon(LANCE) == slot, "add fills slot %d in order" % (slot + 1))
	check(rack.occupied_count() == WeaponRack.DEFAULT_CAPACITY and rack.add_weapon(CLEAVER) == -1, "a full rack refuses another weapon")
	var slot_copy: Array[WeaponDefinition] = rack.slots()
	slot_copy[0] = null
	check(rack.weapon_at(0) == LANCE, "slots returns a copy rather than mutable rack storage")
	check(rack.weapons().size() == WeaponRack.DEFAULT_CAPACITY, "weapons reports occupied definitions in order")

	# Controllers have independent cooldown and flash state even when definitions
	# are shared. A concrete hit also proves the original damage is unchanged.
	var first: WeaponController = rack.controller_at(0)
	second = rack.controller_at(1)
	var enemy: ArenaEnemy = load("res://scenes/actors/enemy.tscn").instantiate()
	enemy.party = arena.party
	enemy.position = players[0].position + Vector2(80, 0)
	arena.get_node("Actors").add_child(enemy)
	var lance_damage: float = LANCE.damage
	first._physics_process(1.0)
	check(first._remaining > 0.0 and first.is_attacking(), "slot 0 controller attacks and tracks its own cooldown")
	check(second._remaining == 0.0 and not second.is_attacking(), "slot 1 remains idle until it acts")
	second._physics_process(1.0)
	check(second._remaining > 0.0 and second.is_attacking(), "slot 1 controller attacks independently")
	check(is_equal_approx(LANCE.damage, lance_damage), "attacking never mutates shared weapon definitions")
	check(not enemy.health.is_alive(), "two injected weapons still use ordinary combat damage")
	check(rack.remove_weapon(1) == CLEAVER and rack.is_slot_empty(1), "removing one weapon does not remove the starter")
	check(rack.weapon_at(0) == LANCE and rack.occupied_count() == 5, "slot removal preserves the rest of the rack")

	# HUD and character sheet describe the actual rack, including empty slots.
	var hud: Variant = arena.get_node("HUD")
	check(hud._cards.size() == 2 and hud._cards[0]._weapon_slots.size() == WeaponRack.DEFAULT_CAPACITY, "each HUD card draws six compact rack slots")
	await process_frame
	var first_slot: PanelContainer = hud._cards[0]._weapon_slots[0]
	var empty_slot: PanelContainer = hud._cards[0]._weapon_slots[1]
	check((first_slot.get_node("Icon") as TextureRect).texture == LANCE.held_texture, "HUD slot 0 shows the owned weapon")
	check((empty_slot.get_node("Empty") as Label).visible, "HUD leaves an empty slot visible")
	hud.open_sheet(players[0])
	await process_frame
	check("Weapons 5/6" in hud._sheet._summary.text and "Empty" in hud._sheet._summary.text, "Build Sheet reports occupancy and empty slots")
	hud._sheet.queue_free()

	# Clearing is explicit and leaves no phantom definitions behind.
	rack.clear()
	check(rack.occupied_count() == 0 and rack.first_empty_slot() == 0 and rack.weapons().is_empty(), "clear empties every slot")
	arena.free()
	await process_frame

	# A four-player scene gets four separate racks and does not inherit injected
	# weapons from a prior run.
	arena = arena_scene.instantiate()
	arena.player_count = 4
	root.add_child(arena)
	await process_frame
	players = arena.party.members()
	check(players.size() == 4, "four-player setup remains supported")
	var seen_racks: Array[WeaponRack] = []
	for player: PenguinPlayer in players:
		check(player.weapon_rack.capacity() == WeaponRack.DEFAULT_CAPACITY and player.weapon_rack.occupied_count() == 1, "each four-player spawn starts with one weapon and five empties")
		check(not seen_racks.has(player.weapon_rack), "each player owns a distinct rack runtime")
		seen_racks.append(player.weapon_rack)
	arena.free()
	await process_frame

	# Room transitions keep the player-owned rack; restarting creates the chosen
	# character loadout fresh rather than carrying inventory into a new run.
	var expedition := load("res://scenes/run/expedition.tscn").instantiate() as Node2D
	root.add_child(expedition)
	await process_frame
	var traveller: PenguinPlayer = expedition.party.members()[0]
	var persisted_rack: WeaponRack = traveller.weapon_rack
	check(persisted_rack.add_weapon(CLEAVER) == 1, "transition check injects a second personal weapon")
	_travel(expedition, expedition.gates()[0])
	await process_frame
	check(expedition.party.members()[0].weapon_rack == persisted_rack and persisted_rack.occupied_count() == 2, "room travel preserves the owned rack and its slots")
	expedition.free()
	await process_frame
	var fresh := arena_scene.instantiate() as Node2D
	root.add_child(fresh)
	await process_frame
	check(fresh.party.members()[0].weapon_rack.occupied_count() == 1 and fresh.party.members()[0].weapon_rack.weapon_at(1) == null, "a restarted run restores the selected starting loadout")
	fresh.free()

	print("WEAPON RACK TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
