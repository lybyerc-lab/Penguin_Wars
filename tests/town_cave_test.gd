extends SceneTree
## Town, services and cave-route integration against the real expedition
## scene. Exit status is nonzero on any failed check.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func service_of(run: Node2D, kind: TownService.Kind) -> TownService:
	for service: TownService in run.services():
		if service.kind == kind:
			return service
	return null

## Stand the whole living party on a gate and hold it past the dwell time.
func travel(run: Node2D, gate: PartyGate) -> void:
	for player: PenguinPlayer in run.party.members(true):
		player.position = gate.position
	gate._physics_process(PartyGate.DWELL + 0.2)

## Drive every wave of the current room without waiting in real time.
func clear_room(run: Node2D) -> void:
	var director: EncounterDirector = run.encounter
	director.auto_advance = true
	for step: int in range(200):
		director._physics_process(10.0)
		for node: Node in get_nodes_in_group("enemies"):
			(node as ArenaEnemy).health.take_damage(DamageEvent.new(1000, 1))
		await process_frame
		if director.state == EncounterDirector.State.COMPLETE:
			break
	director.auto_advance = false

func _run() -> void:
	# --- cave data integrity ------------------------------------------
	var cave: CaveDefinition = load("res://resources/caves/hollow_shelf.tres")
	check(cave.unresolved_exits().is_empty(), "every cave exit resolves to a room")
	check(cave.entrance() != null and cave.entrance().id == &"shelf_mouth", "cave entrance is the shelf mouth")
	check(cave.room(&"glitter_seam") != null, "named rooms resolve")
	check(cave.room(&"nowhere") == null, "unknown room names do not resolve")
	check(CaveDefinition.new().entrance() == null, "an empty cave has no entrance")

	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	root.add_child(run)
	await process_frame
	var party: PartyRoster = run.party
	var wallet: RunWallet = run.get_node("Wallet")
	var market: TownMarket = run.market
	var players: Array[PenguinPlayer] = party.members()
	check(players.size() == 2, "expedition starts with a party")

	# --- town ----------------------------------------------------------
	check(run.room.kind == RoomDefinition.Kind.TOWN, "the party starts in town")
	check(run.encounter.state == EncounterDirector.State.READY, "town runs no encounter")
	check(run.services().size() == 4, "town builds its four services")
	check(run.gates().size() == 1 and not run.gates()[0].locked, "the cave mouth is open")
	check(players[0].arena_bounds == run.room.bounds, "players take the town's own bounds")

	var nurse: TownService = service_of(run, TownService.Kind.NURSE)
	var smith: TownService = service_of(run, TownService.Kind.BLACKSMITH)
	var hall: TownService = service_of(run, TownService.Kind.TOWN_HALL)
	check(nurse != null and smith != null and hall != null, "shop, nurse, smith and hall are present")
	check(nurse.occupants().is_empty(), "nobody is inside a building at the start")
	players[0].position = nurse.position
	check(nurse.occupants().size() == 1 and nurse.occupants()[0] == players[0], "standing in a zone opens that service")

	# --- buying --------------------------------------------------------
	players[0].health.take_damage(DamageEvent.new(50))
	check(players[0].health.current == 50.0, "test damage applied")
	check(not market.buy(1, TownService.Kind.SHOP, 0), "an empty wallet buys nothing")
	check(players[0].health.current == 50.0, "a refused purchase changes nothing")
	wallet.credit(1, 60)
	check(market.buy(1, TownService.Kind.SHOP, 0), "herring ration purchased")
	check(players[0].health.current == 90.0, "the ration restores health")
	check(wallet.balance(1) == 56, "the ration is paid for")
	check(wallet.balance(2) == 0, "one penguin's purchase leaves the other's wallet alone")
	check(not market.buy(1, TownService.Kind.SHOP, 9), "an unknown offer is refused")

	var max_before: float = players[0].health.maximum
	check(market.buy(1, TownService.Kind.SHOP, 1), "packed snow purchased")
	check(players[0].health.maximum == max_before + 12.0, "packed snow raises maximum health")

	# --- the nurse can raise a downed penguin --------------------------
	players[1].health.take_damage(DamageEvent.new(500))
	check(not players[1].health.is_alive(), "second penguin is down")
	check(players[1].collision_layer == 0, "a downed penguin stops colliding")
	check(not market.buy(2, TownService.Kind.NURSE, 0), "a downed penguin cannot trade for itself")
	check(market.buy(1, TownService.Kind.NURSE, 1), "the nurse rouses a fallen friend")
	check(players[1].health.is_alive(), "the roused penguin is standing")
	check(is_equal_approx(players[1].health.current, players[1].health.maximum * TownMarket.REVIVE_FRACTION), "revival returns a fraction of health")
	check(players[1].collision_layer != 0, "a roused penguin collides again")
	check(not market.buy(1, TownService.Kind.NURSE, 1), "nobody left to rouse")
	var roused_at: float = players[1].health.current
	players[1].health.heal(10.0)
	check(players[1].health.current == roused_at + 10.0, "a roused penguin heals normally again")

	# --- the blacksmith ------------------------------------------------
	var carried: WeaponDefinition = players[0].weapon.definition
	check(market.buy(1, TownService.Kind.BLACKSMITH, 2), "weapon traded")
	check(players[0].weapon.definition != carried, "the trade changes the carried weapon")
	check(market.buy(1, TownService.Kind.BLACKSMITH, 2), "weapon traded back")
	check(players[0].weapon.definition == carried, "trading twice returns the original weapon")
	var damage_before: float = players[0].weapon.damage_bonus
	check(market.buy(1, TownService.Kind.BLACKSMITH, 0), "edge honed")
	check(players[0].weapon.damage_bonus == damage_before + 4.0, "honing raises weapon damage")
	check(market.offers(TownService.Kind.TOWN_HALL).is_empty(), "the town hall sells nothing")

	# --- into the cave -------------------------------------------------
	var opening_lines: PackedStringArray = run.journal.town_hall_lines()
	players[0].experience.grant(12)
	var level_before: int = players[0].experience.level
	var purse_before: int = wallet.balance(1)
	var health_before: float = players[0].health.current
	travel(run, run.gates()[0])
	await process_frame
	check(run.room.id == &"shelf_mouth", "the party travels into the cave entrance")
	check(run.cave != null and run.cave.id == &"hollow_shelf", "the expedition tracks its cave")
	check(players[0].arena_bounds == run.room.bounds, "each room applies its own bounds")
	check(run.encounter.actor_bounds == run.room.bounds, "spawned enemies take the room's bounds")
	check(run.encounter.spawn_ring == run.room.spawn_ring, "the room owns its spawn ring")
	check(run.services().is_empty(), "town buildings do not follow the party underground")
	check(wallet.balance(1) == purse_before, "wallets survive a room change")
	check(players[0].experience.level == level_before, "levels survive a room change")
	check(players[0].health.current == health_before, "health survives a room change")
	check(run.gates().size() == 2, "the entrance room offers a branch")
	for gate: PartyGate in run.gates():
		check(gate.locked, "routes stay shut while the room is hostile")
	travel(run, run.gates()[0])
	check(run.room.id == &"shelf_mouth", "a locked route does not move the party")

	await clear_room(run)
	check(run.encounter.state == EncounterDirector.State.COMPLETE, "the entrance room can be cleared")
	for gate: PartyGate in run.gates():
		check(not gate.locked, "clearing the room opens both routes")
	check(run.journal.rooms_cleared == 1, "the journal records a cleared room")

	# --- the supply branch ---------------------------------------------
	var seam_gate: PartyGate = run.gates()[0]
	check(seam_gate.exit.target_id == &"glitter_seam", "the first route leads to the seam")
	travel(run, seam_gate)
	await process_frame
	check(run.room.id == &"glitter_seam", "the party takes the supply branch")
	check(run.room.kind == RoomDefinition.Kind.SUPPLY, "the seam is a supply room")
	check(run.encounter.state == EncounterDirector.State.READY, "a supply room starts no waves")
	var snowmen: int = 0
	for node: Node in run.get_node("Actors").get_children():
		if node is SupplySnowman:
			snowmen += 1
	check(snowmen == run.room.supply_points.size(), "a supply room stocks its snowmen without a wave")
	check(run.gates().size() == 1 and not run.gates()[0].locked, "a room with no fight opens its exit at once")

	# --- the final room and the way home --------------------------------
	travel(run, run.gates()[0])
	await process_frame
	check(run.room.id == &"black_ledge", "both branches meet at the ledge")
	var leftover: int = 0
	for node: Node in run.get_node("Actors").get_children():
		if node is SupplySnowman:
			leftover += 1
	check(leftover == run.room.supply_points.size(), "the previous room's props do not follow")
	await clear_room(run)
	check(run.gates().size() == 1 and run.gates()[0].exit.leads_outside(), "the ledge leads home")
	check(not run.journal.cleared(run.cave), "the cave is not cleared until the party leaves")
	travel(run, run.gates()[0])
	await process_frame
	check(run.room.kind == RoomDefinition.Kind.TOWN, "the party returns to town")
	check(run.journal.caves_cleared.size() == 1, "the journal records the cleared cave")
	check(run.services().size() == 4, "town rebuilds its services on return")
	check(run.journal.town_hall_lines() != opening_lines, "the town hall meeting changes after a cave")
	check(wallet.balance(1) > 0, "snowflakes come home with the party")

	run.free()
	check(get_nodes_in_group("enemies").is_empty(), "no actors leak when the run ends")
	print("TOWN & CAVE TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
