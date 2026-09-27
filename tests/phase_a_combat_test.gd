extends SceneTree
## Focused proof for the first Frozen Coast combat ecosystem. This deliberately
## tests mechanics and data only; Claude's production environment/art plugs in
## later without changing these combat rules.

var failures: int = 0
const FISH_SPEAR: WeaponDefinition = preload("res://resources/weapons/fish_spear.tres")
const SLINGSHOT: WeaponDefinition = preload("res://resources/weapons/icicle_slingshot.tres")
const SNOWBOMB: WeaponDefinition = preload("res://resources/weapons/snowbomb.tres")
const ROLLY: PackedScene = preload("res://scenes/actors/rolly.tscn")
const SKUA: PackedScene = preload("res://scenes/actors/skua_slinger.tscn")
const TUSKBULL: PackedScene = preload("res://scenes/actors/tuskbull.tscn")
const DRIFTFIELD: EncounterDefinition = preload("res://resources/encounters/driftfield_phase_a.tres")

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _spawn(arena: Node2D, scene: PackedScene, at: Vector2) -> ArenaEnemy:
	var enemy := scene.instantiate() as ArenaEnemy
	enemy.party = arena.party
	enemy.position = at
	arena.get_node("Actors").add_child(enemy)
	enemy.set_physics_process(false)
	return enemy

func _clear_enemies(arena: Node2D) -> void:
	for node: Node in arena.get_node("Actors").get_children():
		if node is ArenaEnemy:
			node.free()

func _role_counts(arena: Node2D) -> Dictionary:
	var counts := {"rolly": 0, "skua": 0, "tuskbull": 0}
	for node: Node in arena.get_node("Actors").get_children():
		if not node is ArenaEnemy:
			continue
		var enemy := node as ArenaEnemy
		if enemy.behavior is RangedBehavior:
			counts["skua"] += 1
		elif enemy.behavior is ChargeBehavior:
			counts["tuskbull"] += 1
		else:
			counts["rolly"] += 1
	return counts

func _run() -> void:
	# Data contracts: all three production-facing starter families have complete
	# tier chains even though Phase A playtesting uses Tier I only.
	for family: String in ["fish_spear", "icicle_slingshot", "snowbomb"]:
		for suffix: String in ["", "_ii", "_iii", "_iv"]:
			var definition := load("res://resources/weapons/%s%s.tres" % [family, suffix]) as WeaponDefinition
			check(definition != null and definition.problems().is_empty(), "%s%s validates as a complete weapon tier" % [family, suffix])
	check(FISH_SPEAR.pattern == WeaponDefinition.Pattern.LINE and FISH_SPEAR.damage_kind == WeaponDefinition.DamageKind.MELEE, "Fish Spear is a melee pierce line")
	check(SLINGSHOT.pattern == WeaponDefinition.Pattern.SINGLE and SLINGSHOT.reach > FISH_SPEAR.reach, "Icicle Slingshot is the long-range single-target starter")
	check(SNOWBOMB.pattern == WeaponDefinition.Pattern.AREA and SNOWBOMB.travel_time > 0.0, "Snowbomb uses a delayed landing-area attack")

	check(DRIFTFIELD.wave_count == 4, "Driftfield Phase A uses four short teaching waves")
	check(DRIFTFIELD.ranged_intro_wave == 2 and DRIFTFIELD.charger_intro_wave == 3, "Driftfield introduces Skua before Tuskbull")
	check(DRIFTFIELD.ranged_cap == 2 and DRIFTFIELD.charger_cap == 1, "Driftfield caps artillery at two and chargers at one")

	var arena := load("res://scenes/arena/test_arena.tscn").instantiate() as Node2D
	root.add_child(arena)
	await process_frame
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	_clear_enemies(arena)
	var player: PenguinPlayer = arena.party.members()[0]
	player.position = Vector2.ZERO

	# Fish Spear: a narrow line can pierce a clump without becoming a broad AoE.
	player.configure_weapon_loadout([FISH_SPEAR])
	var spear: WeaponController = player.weapon_rack.controller_at(0)
	spear.set_physics_process(false)
	var line_a := _spawn(arena, ROLLY, Vector2(70, 0))
	var line_b := _spawn(arena, ROLLY, Vector2(112, 4))
	var line_side := _spawn(arena, ROLLY, Vector2(92, 34))
	spear._physics_process(1.0)
	check(not line_a.health.is_alive() and not line_b.health.is_alive(), "Fish Spear pierces two Rollies in its committed line")
	check(line_side.health.is_alive(), "Fish Spear does not turn into a wide cleave")
	_clear_enemies(arena)

	# Slingshot: nearest-target pressure with no accidental splash.
	player.configure_weapon_loadout([SLINGSHOT])
	var sling: WeaponController = player.weapon_rack.controller_at(0)
	sling.set_physics_process(false)
	var near := _spawn(arena, ROLLY, Vector2(110, 0))
	var far := _spawn(arena, ROLLY, Vector2(180, 0))
	sling._physics_process(1.0)
	check(is_equal_approx(near.health.current, 7.0), "Icicle Slingshot damages the nearest Rolly")
	check(is_equal_approx(far.health.current, 16.0), "Icicle Slingshot stays single target")
	_clear_enemies(arena)

	# Snowbomb: landing point is locked, then current occupants of the radius are
	# damaged at impact. This is the cluster answer, not a hard enemy counter.
	player.configure_weapon_loadout([SNOWBOMB])
	var bomb: WeaponController = player.weapon_rack.controller_at(0)
	bomb.set_physics_process(false)
	var bomb_a := _spawn(arena, ROLLY, Vector2(160, 0))
	var bomb_b := _spawn(arena, ROLLY, Vector2(210, 0))
	var bomb_outside := _spawn(arena, ROLLY, Vector2(260, 0))
	bomb._physics_process(1.0)
	check(bomb.is_projectile_in_flight(), "Snowbomb has a readable travel window")
	check(bomb_a.health.current == 16.0 and bomb_b.health.current == 16.0, "Snowbomb does not deal invisible instant damage")
	bomb._physics_process(SNOWBOMB.travel_time + 0.01)
	check(not bomb_a.health.is_alive() and not bomb_b.health.is_alive(), "Snowbomb clears a tight Rolly cluster at impact")
	check(bomb_outside.health.is_alive(), "Snowbomb radius is bounded")
	_clear_enemies(arena)

	# Skua Slinger: the landing point is committed during the tell. Moving after
	# the windup starts should dodge the egg rather than drag the telegraph.
	var skua := _spawn(arena, SKUA, Vector2.ZERO)
	var artillery := skua.behavior as SkuaSlingerBehavior
	player.position = Vector2(250, 0)
	artillery.movement(skua, player, 1.0)
	check(artillery.state == RangedBehavior.State.WINDUP, "Skua Slinger enters a readable artillery windup")
	var locked_landing: Vector2 = artillery.locked_target
	player.position = Vector2(250, 110)
	artillery.movement(skua, player, artillery.windup_time + 0.01)
	var eggs: Array[Node] = get_nodes_in_group("enemy_projectiles")
	var egg := eggs[0] as SkuaIceEgg if not eggs.is_empty() else null
	if egg != null:
		egg.set_physics_process(false)
	check(egg != null and egg.landing_position == locked_landing, "Skua egg lands on the warned point instead of homing")
	if egg != null:
		egg.free()
	_clear_enemies(arena)

	# Tuskbull: the warned charge locks direction and a hard-terrain collision
	# enters the longer crash punish window.
	var bull := _spawn(arena, TUSKBULL, Vector2.ZERO)
	var charge := bull.behavior as ChargeBehavior
	player.position = Vector2(150, 0)
	check(charge.movement(bull, player, 0.01) == Vector2.ZERO and charge.state == ChargeBehavior.State.WINDUP, "Tuskbull begins with a stationary lane tell")
	var committed: Vector2 = charge.movement(bull, player, charge.windup_time + 0.01)
	check(charge.state == ChargeBehavior.State.CHARGE and committed.x > 400.0, "Tuskbull commits to the warned lane")
	charge.on_world_collision()
	check(charge.state == ChargeBehavior.State.RECOVER and is_equal_approx(charge.remaining, charge.crash_recovery_time), "hard collision stuns Tuskbull into the longer punish window")
	check(not charge.contact_enabled(), "crashed Tuskbull is safe to punish")
	_clear_enemies(arena)

	# Encounter data teaches roles without a second director or hand-authored
	# per-wave manager.
	var director := EncounterDirector.new()
	director.definition = DRIFTFIELD
	director.party = arena.party
	director.actor_root = arena.get_node("Actors")
	arena.add_child(director)
	director.set_physics_process(false)

	director.wave = 1
	director._spawn_index = 0
	for index: int in range(6):
		director._spawn_enemy()
	var counts: Dictionary = _role_counts(arena)
	check(counts["rolly"] == 6 and counts["skua"] == 0 and counts["tuskbull"] == 0, "wave 1 teaches Rolly pressure alone")
	_clear_enemies(arena)

	director.wave = 2
	director._spawn_index = 0
	for index: int in range(8):
		director._spawn_enemy()
	counts = _role_counts(arena)
	check(counts["skua"] == 2 and counts["tuskbull"] == 0, "wave 2 adds at most two Skua Slingers")
	_clear_enemies(arena)

	director.wave = 3
	director._spawn_index = 0
	for index: int in range(DRIFTFIELD.base_count + 4):
		director._spawn_enemy()
	counts = _role_counts(arena)
	check(counts["skua"] == 2 and counts["tuskbull"] == 1 and counts["rolly"] == 7, "wave 3 adds one Tuskbull while preserving swarm pressure")
	_clear_enemies(arena)

	arena.free()
	print("PHASE A COMBAT TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)