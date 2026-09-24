extends SceneTree
## Verify production base/scarf presentation for each supported local player count.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/arena/test_arena.tscn") as PackedScene
	for count in range(1, 5):
		var arena := packed.instantiate() as Node2D
		arena.set("player_count", count)
		root.add_child(arena)
		await process_frame
		var players: Array[PenguinPlayer] = (arena.get_node("Party") as PartyRoster).members()
		if players.size() != count:
			push_error("Expected %d players, found %d" % [count, players.size()])
			quit(1)
			return
		var tints: Array[Color] = []
		for player in players:
			var visual := player.get_node("CharacterVisual") as CharacterVisual
			if visual.profile == null or visual.animated_sprite.modulate != Color.WHITE:
				push_error("Base presentation is missing or tinted at count %d" % count)
				quit(1)
				return
			if visual.scarf_sprite.modulate != player.identity.tint or tints.has(player.identity.tint):
				push_error("Scarf tint is missing or reused at count %d" % count)
				quit(1)
				return
			if visual.animated_sprite.animation != visual.scarf_sprite.animation or visual.animated_sprite.frame != visual.scarf_sprite.frame:
				push_error("Base and scarf are not synchronized at count %d" % count)
				quit(1)
				return
			tints.append(player.identity.tint)
		print("SCARF TINT PASS ", count, " players: ", tints)
		arena.queue_free()
		await process_frame
	print("CHARACTER SCARF TINT TEST: PASS")
	quit(0)
