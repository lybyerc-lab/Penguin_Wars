extends SceneTree

const OUTPUT := "res://docs/reviews/gameplay-presentation-v1/driftfield-mobile-combat.png"
const ROOM: RoomDefinition = preload("res://resources/rooms/driftfield_phase_a.tres")
const SPEAR: WeaponDefinition = preload("res://resources/weapons/fish_spear.tres")
const SLINGSHOT: WeaponDefinition = preload("res://resources/weapons/icicle_slingshot.tres")
const BOMB: WeaponDefinition = preload("res://resources/weapons/snowbomb.tres")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(2340, 1080)
	var run := preload("res://scenes/prototypes/phase_a_expedition_review.tscn").instantiate() as Node2D
	run.mobile_preview = true
	root.add_child(run)
	await process_frame
	run._enter_room(ROOM)
	await process_frame
	run.encounter.set_physics_process(false)
	for child: Node in run.get_node("Actors").get_children():
		if child is ArenaEnemy: child.queue_free()
	await process_frame
	run.encounter.alive_count = 0
	var player: PenguinPlayer = run.party.members()[0]
	player.position = Vector2(-700, -1960)
	player.configure_weapon_loadout([SPEAR, SLINGSHOT, BOMB])
	var rolly: PackedScene = preload("res://scenes/actors/rolly.tscn")
	var skua: PackedScene = preload("res://scenes/actors/skua_slinger.tscn")
	var tuskbull: PackedScene = preload("res://scenes/actors/tuskbull.tscn")
	var entries: Array[Dictionary] = [
		{"scene": rolly, "position": player.position + Vector2(-260, -120)},
		{"scene": rolly, "position": player.position + Vector2(250, 100)},
		{"scene": skua, "position": player.position + Vector2(330, -140)},
		{"scene": tuskbull, "position": player.position + Vector2(-360, 120)},
	]
	run.encounter.spawn_ambush(entries)
	for frame: int in range(90): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var result: Error = root.get_texture().get_image().save_png(OUTPUT)
	print("GAMEPLAY PRESENTATION V1 RENDER: ", "PASS" if result == OK else "FAIL", " · ", ProjectSettings.globalize_path(OUTPUT))
	quit(0 if result == OK else 1)
