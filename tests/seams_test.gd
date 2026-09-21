extends SceneTree
## The extension points other lanes plug into: the optional boss phase, run
## modifiers, character selection, campaign and save state, and regions.
## Everything here is the seam, not an implementation of the feature behind it.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func boss_data(scene_path: String, reward: int = 7) -> BossDefinition:
	var data := BossDefinition.new()
	data.id = &"stub"
	data.display_name = "Stub Boss"
	data.scene = load(scene_path) if not scene_path.is_empty() else null
	data.reward = reward
	data.maximum_health = 300.0
	data.party_health_scaling = 0.5
	return data

func encounter_with(boss: BossDefinition, difficulty: float = 1.0) -> EncounterDefinition:
	var data := EncounterDefinition.new()
	data.enemy_scene = load("res://scenes/actors/enemy.tscn")
	data.base_count = 1
	data.spawn_interval = 0.1
	data.wave_count = 1
	data.run_seed = 404
	data.boss = boss
	data.difficulty_multiplier = difficulty
	return data

## Drives the director to its next resting state without waiting in real time.
func drive(director: EncounterDirector, stop: Array) -> void:
	for step: int in range(120):
		director._physics_process(10.0)
		for node: Node in get_nodes_in_group("enemies"):
			if node is BossActor:
				continue
			(node as ArenaEnemy).health.take_damage(DamageEvent.new(10000, 1))
		await process_frame
		if director.state in stop:
			return

func _run() -> void:
	# =================================================================
	# Boss phase seam
	# =================================================================
	var arena: Node2D = load("res://scenes/arena/test_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	var director: EncounterDirector = arena.encounter
	var wallet: RunWallet = arena.get_node("Wallet")
	var data: BossDefinition = boss_data("res://tests/stub_boss.tscn")
	director.reset()
	director.definition = encounter_with(data)
	var announced: Array[BossActor] = []
	director.boss_started.connect(func(boss: BossActor) -> void: announced.append(boss))
	director.auto_advance = true
	director.start()
	await drive(director, [EncounterDirector.State.BOSS, EncounterDirector.State.COMPLETE])
	check(director.state == EncounterDirector.State.BOSS, "a boss phase follows the final wave")
	var boss: BossActor = director.active_boss
	check(is_instance_valid(boss), "the director spawned the scene the definition named")
	check(boss is BossActor, "a boss is a BossActor")
	check(announced.size() == 1 and announced[0] == boss, "boss_started announces the boss once")
	check(boss.boss_definition == data, "the boss keeps its definition")
	check(boss.title() == "Stub Boss", "the boss reports its name for a bar to show")
	check(boss.configure_calls == 1, "configure runs exactly once")
	check(boss.configured_party_size == arena.party.members().size(), "configure is told the party size")
	# 300 base, +50% for the second penguin.
	check(is_equal_approx(boss.health_after_configure, 450.0), "party scaling is applied in configure")
	check(is_equal_approx(boss.health.current, boss.health.maximum), "configure ran before the tree took current from maximum")
	check(boss.is_in_group("enemies"), "a boss is an ordinary target")
	check(boss.hit_radius == 40.0, "a boss may set its own body in configure")
	check(director.actor_bounds.encloses(boss.arena_bounds), "a boss is bounded inside the room")

	var felled: Array[BossActor] = []
	director.boss_defeated.connect(func(fallen: BossActor) -> void: felled.append(fallen))
	check(boss.phase() == "", "a boss reports no phase by default")
	var announcements: Array[int] = [0]
	boss.presentation_changed.connect(func() -> void: announcements[0] += 1)
	boss.announce()
	check(announcements[0] == 1, "a boss can tell a bar its presentation changed")
	var before_one: int = wallet.balance(1)
	var before_two: int = wallet.balance(2)
	boss.health.take_damage(DamageEvent.new(100000, 1))
	director._physics_process(0.1)
	check(director.state == EncounterDirector.State.COMPLETE, "the room completes when the boss falls")
	check(director.active_boss == null, "the defeated boss is released")
	check(wallet.balance(1) == before_one + data.reward, "the boss reward reaches the party")
	check(wallet.balance(2) == before_two + data.reward, "every living penguin is paid")
	boss.health.take_damage(DamageEvent.new(100, 1))
	check(wallet.balance(1) == before_one + data.reward, "a dead boss cannot pay twice")
	check(felled.size() == 1 and felled[0] == boss, "boss_defeated announces the boss once")

	# The scaling contract: the director applies room and run difficulty AFTER
	# configure, so a boss that reapplied them would land here at double.
	var loaded := RunModifiers.new()
	loaded.enemy_health_scale = 2.0
	loaded.enemy_damage_scale = 2.0
	director.reset()
	director.modifiers = loaded
	director.definition = encounter_with(boss_data("res://tests/stub_boss.tscn"), 1.5)
	director.auto_advance = true
	director.start()
	await drive(director, [EncounterDirector.State.BOSS, EncounterDirector.State.COMPLETE])
	var scaled_boss: BossActor = director.active_boss
	check(is_instance_valid(scaled_boss), "the scaled boss spawned")
	check(is_equal_approx(scaled_boss.health_after_configure, 450.0), "configure sees base values, not scaled ones")
	check(is_equal_approx(scaled_boss.health.maximum, 450.0 * 3.0), "the director applies room and run scaling exactly once")
	check(is_equal_approx(scaled_boss.contact_damage, 16.0 * 3.0), "boss damage is scaled once, by the director")
	check(is_equal_approx(scaled_boss.projectile_damage, 16.0 * 3.0), "boss projectile damage is scaled once")
	check(scaled_boss.room_bounds == director.actor_bounds, "a boss keeps the whole room for its shots")
	check(director.actor_bounds.encloses(scaled_boss.arena_bounds), "a large body is inset from the wall")
	scaled_boss.health.take_damage(DamageEvent.new(100000, 1))
	director._physics_process(0.1)
	director.modifiers = RunModifiers.new()

	# A boss that cannot be built must not leave an uncompletable room.
	director.reset()
	director.definition = encounter_with(boss_data(""))
	director.start()
	await drive(director, [EncounterDirector.State.COMPLETE])
	check(director.state == EncounterDirector.State.COMPLETE, "a boss with no scene still completes the room")

	# No boss at all is the ordinary path and must be unchanged.
	director.reset()
	director.definition = encounter_with(null)
	director.start()
	await drive(director, [EncounterDirector.State.COMPLETE])
	check(director.state == EncounterDirector.State.COMPLETE, "a room with no boss completes on its last wave")

	# =================================================================
	# Boss schedule: selection only
	# =================================================================
	var ladder := BossSchedule.new()
	check(ladder.boss_for(5) == null and ladder.problems().is_empty(), "an empty schedule selects nothing and is not broken")
	var small := boss_data("res://tests/stub_boss.tscn")
	var large := boss_data("res://tests/stub_boss.tscn")
	large.id = &"stub_large"
	var low := BossTier.new()
	low.every = 5
	low.boss = small
	var high := BossTier.new()
	high.every = 20
	high.boss = large
	var rungs: Array[BossTier] = [low, high]
	ladder.tiers = rungs
	check(ladder.boss_for(4) == null, "an ordinary index carries no boss")
	check(ladder.boss_for(5) == small, "a milestone selects its rung")
	check(ladder.boss_for(20) == large, "the larger interval outranks the smaller one")
	check(ladder.boss_for(40) == large, "precedence holds on later cycles")
	check(ladder.boss_for(0) == null and ladder.boss_for(-5) == null, "non-positive indexes carry no boss")
	check(ladder.is_milestone(10) and not ladder.is_milestone(11), "milestones are reported")
	check(ladder.milestones(20) == PackedInt32Array([5, 10, 15, 20]), "the ladder lists its milestones")
	check(ladder.problems().is_empty(), "a well-formed ladder reports nothing")
	var clash := BossTier.new()
	clash.every = 5
	clash.boss = null
	var bad: Array[BossTier] = [low, clash]
	ladder.tiers = bad
	check(ladder.problems().size() >= 2, "a duplicate interval and a missing boss are both reported")

	# =================================================================
	# Run modifiers seam
	# =================================================================
	check(RunModifiers.new().is_identity(), "the default run has no modifiers")
	var harsh := RunModifiers.new()
	harsh.enemy_health_scale = 2.0
	harsh.enemy_damage_scale = 3.0
	director.reset()
	director.modifiers = harsh
	director.definition = encounter_with(null, 1.5)
	check(is_equal_approx(director.health_scale(), 3.0), "room difficulty and run modifiers compose")
	check(is_equal_approx(director.damage_scale(), 4.5), "damage composes the same way")
	director.start()
	director._physics_process(10.0)
	var spawned: ArenaEnemy = null
	for node: Node in get_nodes_in_group("enemies"):
		spawned = node as ArenaEnemy
	check(spawned != null, "an enemy spawned under modifiers")
	check(spawned != null and is_equal_approx(spawned.health.maximum, 28.0 * 3.0), "run modifiers scale enemy health")
	check(spawned != null and is_equal_approx(spawned.contact_damage, 8.0 * 4.5), "run modifiers scale enemy damage")
	check(spawned != null and spawned.room_bounds == director.actor_bounds, "a spawned enemy carries the room's own rect")
	arena.free()
	await process_frame

	var generous := RunModifiers.new()
	generous.income_scale = 3.0
	generous.starting_snowflakes = 12
	var rich: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	rich.modifiers = generous
	root.add_child(rich)
	await process_frame
	var purse: RunWallet = rich.get_node("Wallet")
	check(purse.balance(1) == 12 and purse.balance(2) == 12, "starting snowflakes reach every penguin")
	check(rich.encounter.modifiers == generous and rich.progression.modifiers == generous, "one place hands the dials to both readers")
	var opening: int = purse.balance(1)
	rich.progression.collect_materials(1, 2)
	check(purse.balance(1) > opening, "income still flows under modifiers")
	check(is_equal_approx(PlayerStats.new().harvest_yield(4, 1.0), 4.0), "an identity income scale changes nothing")
	check(PlayerStats.new().harvest_yield(4, 2.5) == 10, "the income dial multiplies before Harvest")
	rich.free()
	await process_frame

	# =================================================================
	# Character selection seam
	# =================================================================
	var default_run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	root.add_child(default_run)
	await process_frame
	var members: Array[PenguinPlayer] = default_run.party.members()
	check(members[0].identity.tint == Color("58dfed") and members[1].identity.tint == Color("ffcb77"), "the default roster keeps the original colours")
	check(members[0].weapon.definition.id == &"ice_lance" and members[1].weapon.definition.id == &"fish_cleaver", "the default roster keeps the original loadout")
	check(members[0].identity.character_id == &"skua", "a slot records which character filled it")
	default_run.free()
	await process_frame

	var solo := CharacterDefinition.new()
	solo.id = &"test_penguin"
	solo.display_name = "Test Penguin"
	solo.tint = Color("ff00ff")
	var solo_loadout: Array[WeaponDefinition] = [load("res://resources/weapons/fish_cleaver.tres")]
	solo.starting_weapons = solo_loadout
	var picks: Array[CharacterDefinition] = [solo]
	var chosen: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	chosen.roster = picks
	root.add_child(chosen)
	await process_frame
	var picked: Array[PenguinPlayer] = chosen.party.members()
	check(picked.size() == 2, "a short roster still fills the party")
	for player: PenguinPlayer in picked:
		check(player.identity.tint == Color("ff00ff"), "a chosen character supplies the tint")
		check(player.identity.character_id == &"test_penguin", "a chosen character is recorded on the slot")
		check(player.weapon.definition == solo.starting_weapons[0], "a chosen character supplies the weapon")
	var locked := CharacterDefinition.new()
	locked.id = &"locked_penguin"
	locked.unlocked_by_default = false
	var progress := CampaignState.new()
	check(solo.selectable(progress), "a default character is selectable with no campaign progress")
	check(not locked.selectable(progress), "a locked character needs an unlock")
	progress.unlock(&"locked_penguin")
	check(locked.selectable(progress), "unlocking makes a character selectable")

	# =================================================================
	# Rule-changing characters
	# =================================================================
	var odd := CharacterDefinition.new()
	odd.id = &"stub_character"
	odd.display_name = "Stub"
	odd.tint = Color("00ffcc")
	odd.body_scale = 0.5
	var odd_stats: Array[UpgradeDefinition] = [load("res://resources/upgrades/vitality.tres")]
	odd.starting_stats = odd_stats
	var odd_traits: Array[PackedScene] = [load("res://tests/stub_trait.tscn")]
	odd.traits = odd_traits
	check(odd.problems().is_empty(), "a well-formed character reports nothing")
	var odd_roster: Array[CharacterDefinition] = [odd]
	var strange: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	strange.roster = odd_roster
	strange.player_count = 1
	root.add_child(strange)
	await process_frame
	var oddity: PenguinPlayer = strange.party.members()[0]
	var rule: CharacterTrait = null
	for node: Node in oddity.get_children():
		if node is CharacterTrait:
			rule = node
	check(rule != null, "a character's trait is added to its penguin")
	check(rule != null and rule.player == oddity, "a trait knows the penguin it belongs to")
	check(rule != null and rule.setups == 1, "a trait is set up exactly once")
	check(is_equal_approx(oddity.speed, rule.speed_before * 2.0), "a trait can change a rule on its own penguin")
	check(is_equal_approx(oddity.stats.armor, 5.0), "a trait can change stats without Player.gd knowing the character")
	check(oddity.health.maximum > 100.0, "starting stats apply through the ordinary upgrade seam")
	check(is_equal_approx(oddity.get_node("CharacterVisual").scale.x, 0.5), "body scale reaches the art")
	var body: CollisionShape2D = oddity.get_node("CollisionShape2D")
	check(body.shape is CircleShape2D and is_equal_approx((body.shape as CircleShape2D).radius, 8.0), "body scale reaches the collision body")
	var other: PenguinPlayer = load("res://scenes/actors/player.tscn").instantiate()
	other.identity = PlayerIdentity.new()
	root.add_child(other)
	await process_frame
	check(is_equal_approx((other.get_node("CollisionShape2D").shape as CircleShape2D).radius, 16.0), "resizing one body does not resize the shared shape")
	other.free()
	strange.free()
	await process_frame

	# =================================================================
	# Township is a hub, not the field shop
	# =================================================================
	var hub: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	root.add_child(hub)
	await process_frame
	var town_purse: RunWallet = hub.get_node("Wallet")
	check(hub.progression.in_town, "the party starts in Township")
	town_purse.credit(1, 500)
	check(not hub.progression.can_choose(1, 0), "Township does not sell field-shop offers")
	check(not hub.progression.choose(1, 0), "a paid offer is refused in Township")
	check(town_purse.balance(1) == 500, "a refused offer costs nothing")
	hub.party.members()[0].experience.grant(99)
	check(hub.progression.pending.get(1, 0) > 0, "levelling grants a free choice")
	check(hub.progression.can_choose(1, 0), "a choice earned underground is spendable in Township")
	check(hub.progression.choose(1, 0), "Township spends free choices")

	# =================================================================
	# Room-bounded projectiles
	# =================================================================
	var actors: Node2D = hub.get_node("Actors")
	var pocket := Rect2(600, -120, 240, 240)
	var stray := EnemySnowball.new()
	stray.party = hub.party
	stray.room_bounds = pocket
	stray.direction = Vector2.RIGHT
	stray.speed = 4000.0
	stray.position = Vector2(720, 0)
	actors.add_child(stray)
	stray._physics_process(0.5)
	check(stray.spent, "an enemy shot dies once it leaves its room")
	var kept := EnemySnowball.new()
	kept.party = hub.party
	kept.room_bounds = pocket
	kept.direction = Vector2.RIGHT
	kept.speed = 100.0
	kept.position = Vector2(700, 0)
	actors.add_child(kept)
	kept._physics_process(0.1)
	check(not kept.spent, "a shot still inside its room keeps flying")
	kept.queue_free()
	await process_frame

	var thrower: ArenaEnemy = load("res://scenes/actors/snowball_thrower.tscn").instantiate()
	thrower.party = hub.party
	thrower.room_bounds = pocket
	thrower.position = Vector2(700, 0)
	actors.add_child(thrower)
	thrower.set_physics_process(false)
	var aimed: PenguinPlayer = hub.party.members()[0]
	aimed.position = Vector2(860, 0)
	var ranged := thrower.behavior as RangedBehavior
	ranged.movement(thrower, aimed, 1.0)
	ranged.movement(thrower, aimed, 1.0)
	var fired: EnemySnowball = null
	for node: Node in get_nodes_in_group("enemy_projectiles"):
		fired = node as EnemySnowball
	check(fired != null, "the thrower fired")
	check(fired != null and fired.room_bounds == pocket, "a shooter hands its own room to its shot")
	# Clear the field: a castle shot expires on contact too, so nothing else
	# may be standing in the way when bounds is the thing under test.
	thrower.queue_free()
	if fired != null:
		fired.queue_free()
	await process_frame

	# The same rule, and the same pair of deltas, for friendly fire.
	var loose := CastleSnowball.new()
	loose.room_bounds = pocket
	loose.direction = Vector2.RIGHT
	loose.position = Vector2(720, 0)
	actors.add_child(loose)
	loose._physics_process(1.0)
	check(bool(loose.get("_spent")), "a castle shot dies once it leaves its room")
	var held := CastleSnowball.new()
	held.room_bounds = Rect2(-3000, -3000, 6000, 6000)
	held.direction = Vector2.RIGHT
	held.position = Vector2(720, 0)
	actors.add_child(held)
	held._physics_process(1.0)
	check(not bool(held.get("_spent")), "the same shot inside a larger room keeps flying")
	hub.free()
	await process_frame

	# =================================================================
	# Campaign and save seams
	# =================================================================
	check(chosen.campaign != null and chosen.journal.campaign == chosen.campaign, "the run journal reports into campaign state")
	check(chosen.campaign.runs_started >= 0, "campaign state survives being read")
	var store := ProfileStore.new()
	check(not store.is_persistent(), "the default profile store promises nothing")
	check(not store.save_campaign(progress), "the default store reports that it did not persist")
	check(store.load_campaign() == progress, "the default store hands back what it was given")
	var state := CampaignState.new()
	var hollow: CaveDefinition = load("res://resources/caves/hollow_shelf.tres")
	check(state.record_cave(hollow.id), "a cave is recorded the first time")
	check(not state.record_cave(hollow.id), "a cave is not recorded twice")
	check(state.has_cleared(hollow.id), "a cleared cave is remembered")
	check(state.unlock(&"thing") and not state.unlock(&"thing"), "an unlock lands once")
	state.mark(&"bosses_felled", 2)
	state.mark(&"bosses_felled")
	check(state.milestone(&"bosses_felled") == 3, "milestones accumulate")
	check(state.milestone(&"never_happened") == 0, "an unset milestone reads zero")
	var ledger := RunJournal.new()
	ledger.campaign = state
	ledger.record_rout()
	ledger.begin_expedition(hollow)
	check(state.runs_lost == 1 and state.runs_started == 1, "run results reach campaign state")
	ledger.free()
	chosen.free()
	await process_frame

	# =================================================================
	# Region seam
	# =================================================================
	var region: RegionDefinition = load("res://resources/regions/kelphollow.tres")
	check(region.problems().is_empty(), "the shipped region is playable")
	check(region.town != null and region.town.kind == RoomDefinition.Kind.TOWN, "a region names its town")
	check(region.cave(&"hollow_shelf") != null, "a region resolves its caves by id")
	check(region.cave(&"nowhere") == null, "an unknown cave does not resolve")
	var broken := RegionDefinition.new()
	check(broken.problems().size() >= 2, "a region with no town and no caves reports both")
	broken.town = load("res://resources/rooms/frostfall_arena.tres")
	var twice: Array[CaveDefinition] = [hollow, hollow]
	broken.caves = twice
	check(not broken.problems().is_empty(), "a town that is not a town is reported")
	var duplicates: bool = false
	for problem: String in broken.problems():
		duplicates = duplicates or problem.contains("twice")
	check(duplicates, "a region listing one cave twice is reported")

	print("SEAM TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
