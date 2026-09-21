extends SceneTree
var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func finish_cave(arena: Node) -> void:
	arena.encounter.auto_advance = true
	for step: int in range(160):
		arena.encounter._physics_process(10)
		for node: Node in arena.get_node("Actors").get_children():
			if node is ArenaEnemy:
				node.health.take_damage(DamageEvent.new(10000, 1))
		await process_frame
		if arena.encounter.state == EncounterDirector.State.COMPLETE:
			return
	check(false, "cave reaches completion")
func _run() -> void:
	var scene: PackedScene = load("res://scenes/arena/test_arena.tscn")
	var arena: Node = scene.instantiate()
	root.add_child(arena)
	await process_frame
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	var journey: CaveJourney = arena.journey
	var player: PenguinPlayer = arena.party.members()[0]
	var wallet: RunWallet = arena.get_node("Wallet")
	var builder: CastleBuilder = arena.get_node("Builder")
	var travel: CaveTravelHUD = arena.get_node("TravelHUD")
	check(not journey.next_cave() and not journey.return_to_town(), "exits locked before final wave")
	wallet.credit(1, 40)
	check(builder.build(1), "castle fixture built")
	player.apply_upgrade(load("res://resources/upgrades/armor.tres"))
	player.health.current = 72
	await finish_cave(arena)
	check(travel._panel.visible and travel._title.text == "CAVE CLEARED!", "completion displays cave cleared banner and exits")
	var balance: int = wallet.balance(1)
	var xp: int = player.experience.xp
	var level: int = player.experience.level
	var reserve: int = arena.progression.reserve
	var choices: int = arena.progression.pending[1]
	check(journey.return_to_town(), "cleared cave can return to town")
	check(journey.in_town and arena.get_node("TownVisual").visible, "town destination visible")
	check(arena.encounter.state == EncounterDirector.State.READY and not player.weapon.is_physics_processing(), "town disables encounters and attacks")
	check(wallet.balance(1) == balance and player.health.current == 72 and player.stats.armor == 2, "town preserves currency, health and build")
	check(player.experience.xp == xp and player.experience.level == level and arena.progression.pending[1] == choices and arena.progression.reserve == reserve, "town retains XP, choices and reserve")
	check(not builder.has_castle(1) and not builder.build(1), "room defenses cleared and building disabled in town")
	check(arena.progression.shop_open(), "town allows existing stat shop")
	check(not journey.return_to_town(), "duplicate town request rejected")
	check(journey.next_cave(), "town entrance resumes next cave")
	check(journey.cave_number == 2 and arena.encounter.wave == 1 and arena.encounter.state == EncounterDirector.State.SPAWNING, "next cave starts at wave one")
	check(arena.encounter.definition.base_count == 8 and journey._base_definition.base_count == 6, "difficulty grows without changing shared definition")
	check(player.weapon.is_physics_processing() and not travel._panel.visible, "combat resumes and exit menu closes")
	check(not journey.next_cave(), "double-click cannot skip another cave")
	var supplies: int = 0
	for node: Node in arena.get_node("Actors").get_children():
		if node is SupplySnowman:
			supplies += 1
	check(supplies == 2, "new cave supplies reset")
	var before_income: int = wallet.balance(1)
	arena.progression.finish_wave(1)
	arena.progression.finish_wave(1)
	check(wallet.balance(1) == before_income + 5, "new cave first-wave income paid exactly once")
	await finish_cave(arena)
	check(journey.next_cave() and journey.cave_number == 3, "cleared cave can directly enter next cave")
	check(not journey.return_to_town(), "cannot exit during resumed combat")
	arena.free()
	# Mobile completion must show the exits, not auto-pause behind the upgrade sheet.
	arena = scene.instantiate()
	arena.mobile_preview = true
	root.add_child(arena)
	await process_frame
	arena.encounter.state = EncounterDirector.State.COMPLETE
	arena.encounter.state_changed.emit()
	check(not paused and not is_instance_valid(arena.get_node("MobileHUD")._sheet), "mobile completion does not open blocking shop")
	check(arena.get_node("TravelHUD")._panel.visible, "mobile exit choices visible")
	arena.get_node("TravelHUD")._town.pressed.emit()
	check(arena.journey.in_town, "town button routes mobile party")
	arena.get_node("TravelHUD")._next.pressed.emit()
	check(arena.journey.cave_number == 2, "mobile entrance button starts next cave")
	arena.free()
	print("CAVE JOURNEY TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
