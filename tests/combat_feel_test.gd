extends SceneTree
var failures: int = 0

class DashInput extends LocalPlayerInput:
	var request: bool = true
	func movement() -> Vector2:
		return Vector2.RIGHT
	func dash_requested() -> bool:
		var result: bool = request
		request = false
		return result

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func spawn_enemy(arena: Node, location: Vector2) -> ArenaEnemy:
	var enemy: ArenaEnemy = load("res://scenes/actors/enemy.tscn").instantiate()
	enemy.party = arena.party
	enemy.position = location
	arena.get_node("Actors").add_child(enemy)
	return enemy

func _run() -> void:
	var arena: Node = load("res://scenes/arena/test_arena.tscn").instantiate()
	root.add_child(arena)
	for node: Node in arena.find_children("*", "", true, false):
		node.set_physics_process(false)
	await physics_frame
	var players: Array[PenguinPlayer] = arena.party.members()
	var player: PenguinPlayer = players[0]
	var input := DashInput.new()
	player.add_child(input)
	player.input_source = input
	player._physics_process(0.016)
	check(player.dash.is_active() and player.velocity.x == 680, "dash increases movement speed")
	player.health.take_damage(DamageEvent.new(8))
	check(player.health.current == 100, "dash prevents damage")
	player._physics_process(0.2)
	player.health.take_damage(DamageEvent.new(8))
	check(player.health.current == 92, "damage resumes after dash")
	input.request = true
	player._physics_process(0.016)
	check(not player.dash.is_active(), "cooldown rejects early dash")
	player._physics_process(1.2)
	input.request = true
	player._physics_process(0.016)
	check(player.dash.is_active(), "dash becomes available again")
	check(not players[1].dash.is_active(), "dash state isolated between players")
	player._physics_process(0.2)
	player.health.take_damage(DamageEvent.new(1000))
	input.request = true
	player._physics_process(2.0)
	check(not player.dash.is_active() and player.velocity == Vector2.ZERO, "dead player cannot dash")
	var wielder: PenguinPlayer = players[1]
	wielder.position = Vector2.ZERO
	var front: ArenaEnemy = spawn_enemy(arena, Vector2(60, 0))
	var side: ArenaEnemy = spawn_enemy(arena, Vector2(70, 40))
	var behind: ArenaEnemy = spawn_enemy(arena, Vector2(-80, 0))
	var distant: ArenaEnemy = spawn_enemy(arena, Vector2(160, 0))
	wielder.weapon._physics_process(2.0)
	check(front.health.current == 6 and side.health.current == 6, "cleaver hits multiple enemies in arc")
	check(behind.health.current == 28 and distant.health.current == 28, "cleaver excludes rear and distant enemies")
	check(front._knockback.x > 0, "hit applies outward knockback")
	wielder.weapon._physics_process(0.01)
	check(front.health.current == 6, "weapon cooldown prevents repeated hit")
	front.free()
	side.free()
	behind.free()
	wielder.weapon.definition = load("res://resources/weapons/ice_lance.tres")
	var second: ArenaEnemy = spawn_enemy(arena, Vector2(180, 0))
	wielder.weapon._physics_process(2.0)
	check(distant.health.current == 14 and second.health.current == 28, "lance hits only nearest enemy at long range")
	check(wielder.weapon.definition.damage == 14, "weapon resource unchanged by hits")
	arena.free()
	print("COMBAT FEEL TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
