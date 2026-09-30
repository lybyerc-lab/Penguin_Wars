extends SceneTree

var failures: int = 0
const WHALER: DiscoveryDefinition = preload("res://resources/discoveries/driftfield_whalers_cache.tres")
const HOARD: DiscoveryDefinition = preload("res://resources/discoveries/driftfield_glint_hoard.tres")
const SPEAR: WeaponDefinition = preload("res://resources/weapons/fish_spear.tres")
const LANCE: WeaponDefinition = preload("res://resources/weapons/ice_lance.tres")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("_run")

func _site(arena: Node2D, definition: DiscoveryDefinition, session: RunSession) -> DiscoverySite:
	var site := preload("res://scenes/props/discovery_site.tscn").instantiate() as DiscoverySite
	site.definition = definition
	site.party = arena.party
	site.encounter = arena.encounter
	site.loot = arena.get_node("Loot")
	site.session = session
	arena.get_node("Actors").add_child(site)
	return site

func _snow_pickups(arena: Node2D) -> Array[RunPickup]:
	var found: Array[RunPickup] = []
	for node: Node in arena.get_node("Actors").get_children():
		if node is RunPickup and (node as RunPickup).kind == RunPickup.Kind.SNOWFLAKE: found.append(node)
	return found

func _run() -> void:
	var arena := load("res://scenes/arena/test_arena.tscn").instantiate() as Node2D
	root.add_child(arena)
	await process_frame
	arena.encounter.set_physics_process(false)
	var player: PenguinPlayer = arena.party.members()[0]
	var other: PenguinPlayer = arena.party.members()[1]
	var session := RunSession.new()
	var site := _site(arena, WHALER, session)
	player.global_position = site.global_position + WHALER.ring_offset
	other.global_position = Vector2(500, 500)
	site._physics_process(1.0)
	player.global_position = Vector2(500, 500)
	site._physics_process(0.5)
	check(is_equal_approx(site.progress, 5.0 / 12.0), "one-player dwell decays by 0.5 per second outside the ring")
	player.global_position = site.global_position + WHALER.ring_offset
	other.global_position = player.global_position
	site._physics_process(0.6)
	check(site.state == DiscoverySite.State.OPEN, "two players complete the remaining dwell at the co-op rate")
	check(player.weapon_rack.weapon_at(1) == SPEAR and session.is_discovery_claimed(WHALER.id), "weapon cache adds its reward to an empty slot and records the claim")

	# The approved V1 reward rule allows duplicates and never merges or replaces.
	player.configure_weapon_loadout([SPEAR])
	var duplicate_site := _site(arena, WHALER, RunSession.new())
	var matured_count := [0]
	player.weapon_rack.matured.connect(func(_changes: Array[WeaponMaturation]) -> void: matured_count[0] += 1)
	duplicate_site._complete(player)
	check(player.weapon_rack.weapon_at(0) == SPEAR and player.weapon_rack.weapon_at(1) == SPEAR, "cache adds a duplicate spear when a slot is open")
	check(matured_count[0] == 0 and player.weapon_rack.weapon_at(0).tier == 1, "cache reward emits no maturation and changes no tier")
	var full: Array[WeaponDefinition] = [SPEAR, LANCE, LANCE, LANCE, LANCE, LANCE]
	player.configure_weapon_loadout(full)
	var before: Array[WeaponDefinition] = player.weapon_rack.slots()
	var full_site := _site(arena, WHALER, RunSession.new())
	full_site._complete(player)
	check(player.weapon_rack.slots() == before and _snow_pickups(arena).back().amount == 30, "full rack with a spear grants exactly 30 Snow without merging")
	player.configure_weapon_loadout([LANCE, LANCE, LANCE, LANCE, LANCE, LANCE])
	before = player.weapon_rack.slots()
	var no_match_site := _site(arena, WHALER, RunSession.new())
	no_match_site._complete(player)
	check(player.weapon_rack.slots() == before and _snow_pickups(arena).back().amount == 30, "full rack without a spear also grants exactly 30 Snow")

	# Claimed state is presentation-only and cannot grant twice.
	var remembered := _site(arena, WHALER, session)
	remembered.claimed = true
	# claimed is normally injected before add_child; rebuild to exercise that path.
	remembered.queue_free()
	var remembered_site := preload("res://scenes/props/discovery_site.tscn").instantiate() as DiscoverySite
	remembered_site.definition = WHALER
	remembered_site.party = arena.party
	remembered_site.encounter = arena.encounter
	remembered_site.loot = arena.get_node("Loot")
	remembered_site.session = session
	remembered_site.claimed = true
	arena.get_node("Actors").add_child(remembered_site)
	check(remembered_site.state == DiscoverySite.State.OPEN and not remembered_site._glints[0].visible, "claimed cache reloads open without its interaction ring or glint")

	# A post-clear hoard uses the existing director and delays reward until all five leave.
	for node: Node in arena.get_node("Actors").get_children():
		if node is ArenaEnemy: node.free()
	arena.encounter.alive_count = 0
	arena.encounter.state = EncounterDirector.State.COMPLETE
	var hoard := _site(arena, HOARD, RunSession.new())
	var snow_before: int = _snow_pickups(arena).size()
	hoard._complete(player)
	check(hoard.state == DiscoverySite.State.AMBUSH and arena.encounter.alive_count == 5, "hoard starts a five-enemy post-clear ambush")
	check(_snow_pickups(arena).size() == snow_before, "hoard reward waits for every ambusher")
	for node: Node in arena.get_node("Actors").get_children():
		if node is ArenaEnemy: (node as ArenaEnemy).health.take_damage(DamageEvent.new(10000, 1))
	await process_frame
	await process_frame
	var has_hoard_reward: bool = false
	for pickup: RunPickup in _snow_pickups(arena): has_hoard_reward = has_hoard_reward or pickup.amount == 15
	check(hoard.state == DiscoverySite.State.OPEN and has_hoard_reward, "hoard opens and creates its 15-Snow reward only after all five ambushers are defeated")

	# COMPLETE is not immune to a wipe while a discovery ambush is active.
	var wipe_entries: Array[Dictionary] = [{"scene": HOARD.ambush[0], "position": Vector2.ZERO}]
	arena.encounter.state = EncounterDirector.State.COMPLETE
	arena.encounter.spawn_ambush(wipe_entries)
	for member: PenguinPlayer in arena.party.members(true): member.health.take_damage(DamageEvent.new(10000))
	arena.encounter._physics_process(0.01)
	check(arena.encounter.state == EncounterDirector.State.FAILED, "post-clear discovery ambush wipe routes the run")

	# Herring Cache stays in the existing missing-only supply flow.
	var loot: ArenaLoot = arena.get_node("Loot")
	loot.supply_points = [Vector2(100, 100)]
	loot.supply_scene = preload("res://scenes/props/herring_cache.tscn")
	loot.resupply()
	var cache: HerringCache
	for node: Node in arena.get_node("Actors").get_children():
		if node is HerringCache: cache = node
	check(cache != null and cache.health.maximum == 28, "Driftfield supply flow instances the 28 HP Herring Cache")
	cache.health.take_damage(DamageEvent.new(1000, 1))
	await process_frame
	check(get_nodes_in_group("room_decals").size() == 1, "breaking the Herring Cache leaves one room decal")
	loot.resupply()
	await process_frame
	check(get_nodes_in_group("room_decals").is_empty(), "resupply removes the nearby broken-cache decal")
	arena.free()
	print("DISCOVERY TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
