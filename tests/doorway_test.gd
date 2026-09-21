extends SceneTree
## Doorway presentation, orientation-aware thresholds, Zelda room-transitions,
## and co-op travel mechanics regression test suite.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func travel(run: Node2D, gate: PartyGate) -> void:
	for player: PenguinPlayer in run.party.members(true):
		player.position = gate.position
	gate._physics_process(PartyGate.DWELL + 0.2)

func clear_room(run: Node2D) -> void:
	var director: EncounterDirector = run.encounter
	director.auto_advance = true
	for step: int in range(200):
		director._physics_process(10.0)
		for node: Node in get_nodes_in_group("enemies"):
			if node is ArenaEnemy:
				node.health.take_damage(DamageEvent.new(1000, 1))
		await process_frame
		if director.state == EncounterDirector.State.COMPLETE:
			break
	director.auto_advance = false

func _run() -> void:
	print("Running Doorway & Zelda Transition regression tests...")

	# --- 1. Exit Side Data Integrity -----------------------------------
	var cave: CaveDefinition = load("res://resources/caves/hollow_shelf.tres")
	check(cave != null, "hollow_shelf cave loads")

	var mouth: RoomDefinition = cave.room(&"shelf_mouth")
	check(mouth != null, "shelf_mouth room found")
	check(mouth.exits.size() == 2, "shelf_mouth has 2 exits")

	var seam_exit: RoomExit = null
	var gallery_exit: RoomExit = null
	for ex: RoomExit in mouth.exits:
		if ex.target_id == &"glitter_seam":
			seam_exit = ex
		elif ex.target_id == &"cracked_gallery":
			gallery_exit = ex

	check(seam_exit != null and seam_exit.side == RoomExit.Side.LEFT,
		  "Hollow Shelf LEFT branch leads to Glitter Seam")
	check(gallery_exit != null and gallery_exit.side == RoomExit.Side.RIGHT,
		  "Hollow Shelf RIGHT branch leads to Cracked Gallery")

	var seam_room: RoomDefinition = cave.room(&"glitter_seam")
	check(seam_room != null and seam_room.exits.size() == 1, "glitter_seam has 1 exit")
	check(seam_room.exits[0].side == RoomExit.Side.BOTTOM, "glitter_seam exit is on BOTTOM wall")

	var gallery_room: RoomDefinition = cave.room(&"cracked_gallery")
	check(gallery_room != null and gallery_room.exits.size() == 1, "cracked_gallery has 1 exit")
	check(gallery_room.exits[0].side == RoomExit.Side.BOTTOM, "cracked_gallery exit is on BOTTOM wall")

	var ledge_room: RoomDefinition = cave.room(&"black_ledge")
	check(ledge_room != null and ledge_room.exits.size() == 1, "black_ledge has 1 exit")
	check(ledge_room.exits[0].side == RoomExit.Side.BOTTOM, "black_ledge exit is on BOTTOM wall")
	check(ledge_room.exits[0].leads_outside(), "black_ledge exit leads outside to town")

	# --- 2. Deterministic Wall Positioning Independent of Viewport -----
	var test_bounds := Rect2(-600, -320, 1200, 640)
	check(RoomExit.wall_position(test_bounds, RoomExit.Side.LEFT) == Vector2(-600, 0),
		  "LEFT wall position is flush at bounds.position.x")
	check(RoomExit.wall_position(test_bounds, RoomExit.Side.RIGHT) == Vector2(600, 0),
		  "RIGHT wall position is flush at bounds.end.x")
	check(RoomExit.wall_position(test_bounds, RoomExit.Side.TOP) == Vector2(0, -320),
		  "TOP wall position is flush at bounds.position.y")
	check(RoomExit.wall_position(test_bounds, RoomExit.Side.BOTTOM) == Vector2(0, 320),
		  "BOTTOM wall position is flush at bounds.end.y")

	# --- 2b. Offset Along The Wall -------------------------------------
	var centred := RoomExit.new()
	centred.side = RoomExit.Side.BOTTOM
	check(centred.offset_along == 0.0, "a new exit is centred on its wall by default")
	check(centred.place_on(test_bounds) == Vector2(0, 320), "a zero offset leaves the doorway centred")

	var west := RoomExit.new()
	west.side = RoomExit.Side.BOTTOM
	west.offset_along = -260.0
	var east := RoomExit.new()
	east.side = RoomExit.Side.BOTTOM
	east.offset_along = 260.0
	check(west.place_on(test_bounds) == Vector2(-260, 320), "a negative offset slides the doorway west")
	check(east.place_on(test_bounds) == Vector2(260, 320), "a positive offset slides it east")
	check(west.place_on(test_bounds) != east.place_on(test_bounds), "two doorways can share one wall")
	check(west.place_on(test_bounds).y == east.place_on(test_bounds).y, "both stay flush against that wall")

	var high := RoomExit.new()
	high.side = RoomExit.Side.LEFT
	high.offset_along = -120.0
	check(high.place_on(test_bounds) == Vector2(-600, -120), "a LEFT doorway offsets along y")

	# The offset is measured from the wall centre, so a bigger room keeps it flush.
	var wide_bounds := Rect2(-900, -500, 1800, 1000)
	check(east.place_on(wide_bounds) == Vector2(260, 500), "offset is relative to the wall centre, not the room size")

	var offset_gate := PartyGate.new()
	offset_gate.exit = east
	offset_gate.place_at_wall(test_bounds)
	check(offset_gate.position == east.place_on(test_bounds), "gate and wall art agree on where a doorway is")
	offset_gate.free()

	# Doorway placement is room geometry. Resize the window for real and check
	# that nothing about it moves.
	var before_resize: Vector2 = east.place_on(test_bounds)
	var original_size: Vector2i = root.size
	root.size = Vector2i(640, 360)
	await process_frame
	check(root.size != original_size, "the test actually resized the viewport")
	check(east.place_on(test_bounds) == before_resize, "a viewport resize does not move a doorway")
	var resized_gate := PartyGate.new()
	resized_gate.exit = east
	resized_gate.place_at_wall(test_bounds)
	check(resized_gate.position == before_resize, "a gate placed after a resize lands in the same place")
	resized_gate.free()
	root.size = original_size
	await process_frame

	# --- 2c. Doorway Dressing Comes From Data --------------------------
	check(seam_exit.presentation == RoomExit.Presentation.CRYSTAL, "the seam doorway is dressed as crystal")
	check(gallery_exit.presentation == RoomExit.Presentation.FRACTURED, "the gallery doorway is dressed as fractured")
	check(ledge_room.exits[0].presentation == RoomExit.Presentation.STANDARD, "the way home is a standard doorway")

	# --- 3. Orientation-Aware Rectangular Thresholds -------------------
	check(PartyGate.DWELL == 0.4, "PartyGate dwell is tuned to 0.4s")
	check(PartyGate.THRESHOLD_DEPTH >= 80.0 and PartyGate.THRESHOLD_DEPTH <= 110.0,
		  "Threshold depth is in recommended 80-110px range")
	check(PartyGate.THRESHOLD_WIDTH >= 120.0 and PartyGate.THRESHOLD_WIDTH <= 150.0,
		  "Threshold width is in recommended 120-150px range")

	# Test LEFT gate threshold orientation
	var left_exit := RoomExit.new()
	left_exit.side = RoomExit.Side.LEFT
	var left_gate := PartyGate.new()
	left_gate.exit = left_exit
	left_gate.place_at_wall(test_bounds)
	check(left_gate.position == Vector2(-600, 0), "left gate placed at (-600, 0)")
	# Inside room point (e.g. x = -560, y = 0 -> local x = +40)
	check(left_gate.threshold.has_point(Vector2(40, 0)), "point inside room is in LEFT threshold")
	# Far inside room point (e.g. x = -400, y = 0 -> local x = +200)
	check(not left_gate.threshold.has_point(Vector2(200, 0)), "point far in room is outside threshold")
	# Outside room point (e.g. local x = -50)
	check(not left_gate.threshold.has_point(Vector2(-50, 0)), "point outside room is outside threshold")
	left_gate.free()

	# Test RIGHT gate threshold orientation
	var right_exit := RoomExit.new()
	right_exit.side = RoomExit.Side.RIGHT
	var right_gate := PartyGate.new()
	right_gate.exit = right_exit
	right_gate.place_at_wall(test_bounds)
	check(right_gate.position == Vector2(600, 0), "right gate placed at (600, 0)")
	# Inside room point (e.g. x = +560, y = 0 -> local x = -40)
	check(right_gate.threshold.has_point(Vector2(-40, 0)), "point inside room is in RIGHT threshold")
	# Far inside room point (e.g. local x = -200)
	check(not right_gate.threshold.has_point(Vector2(-200, 0)), "point far in room is outside threshold")
	right_gate.free()

	# --- 4. Live Expedition & Co-op Travel Mechanics -------------------
	var run: Node2D = load("res://scenes/run/expedition.tscn").instantiate()
	root.add_child(run)
	await process_frame

	var party: PartyRoster = run.party
	var players: Array[PenguinPlayer] = party.members()
	check(players.size() == 2, "2 players spawned in expedition")

	# Check town cave mouth uses Side.BOTTOM and doorway threshold
	var town_gates: Array[PartyGate] = run.gates()
	check(town_gates.size() == 1, "town has 1 cave mouth gate")
	var town_gate: PartyGate = town_gates[0]
	check(town_gate.exit.side == RoomExit.Side.BOTTOM, "town cave mouth is on BOTTOM wall")
	check(not town_gate.locked, "town cave mouth is unlocked")
	check(town_gate.exit.presentation == RoomExit.Presentation.EXPEDITION_MOUTH,
		  "the town mouth is dressed by data, not by the name of the cave beyond")
	check(town_gate.is_town_mouth(), "the gate reads that dressing")
	# One cave means one centred mouth; the offset is what keeps a second from stacking.
	check(town_gate.exit.offset_along == 0.0, "a single cave mouth stays centred")
	check(town_gate.position == town_gate.exit.place_on(run.room.bounds), "the mouth sits where its data says")

	# One player alone inside threshold does NOT travel
	players[0].global_position = town_gate.global_position
	players[1].global_position = Vector2(0, 0)
	town_gate._physics_process(0.1)
	check(town_gate.standing() == 1, "only 1 player standing in threshold")
	check(town_gate.missing() == 1, "1 player missing from threshold")
	check(town_gate.dwell == 0.0, "dwell does not accumulate with missing player")
	check(town_gate._waiting_text() == "WAITING FOR P2", "waiting text displays 'WAITING FOR P2'")
	check(run.room.kind == RoomDefinition.Kind.TOWN, "party has not travelled")

	# Stepping out cancels / decays dwell
	players[1].global_position = town_gate.global_position
	town_gate._physics_process(0.2)
	check(town_gate.dwell > 0.15, "dwell accumulated with both players present")
	players[0].global_position = Vector2(0, 0)
	town_gate._physics_process(0.1)
	check(town_gate.dwell < 0.15, "dwell decayed after player stepped out")

	# Downed player ignored: If player 2 is downed, player 1 alone CAN travel
	players[1].health.take_damage(DamageEvent.new(999))
	check(not players[1].health.is_alive(), "player 2 is downed")
	players[0].global_position = town_gate.global_position
	check(town_gate.standing() == 1, "living player 1 standing in threshold")
	check(town_gate.missing() == 0, "0 missing because downed player is ignored")
	town_gate._physics_process(PartyGate.DWELL + 0.1)
	await process_frame
	check(run.room.id == &"shelf_mouth", "entered shelf_mouth with downed player ignored")

	# Revive player 2 for subsequent tests
	players[1].health.revive(100.0)
	check(players[1].health.is_alive(), "player 2 revived")

	# --- 5. Hollow Shelf Entrance Branching ----------------------------
	var mouth_gates: Array[PartyGate] = run.gates()
	check(mouth_gates.size() == 2, "Hollow Shelf has 2 branches")
	for gate: PartyGate in mouth_gates:
		check(gate.locked, "branch doorways locked while combat active")

	# Locked gate refuses travel even with whole party present
	travel(run, mouth_gates[0])
	check(run.room.id == &"shelf_mouth", "locked doorway refuses travel")

	# Clear combat -> doorways open
	await clear_room(run)
	check(run.encounter.state == EncounterDirector.State.COMPLETE, "mouth combat cleared")
	for gate: PartyGate in mouth_gates:
		check(not gate.locked, "doorway unlocked after room clear")

	# Verify banner copy is natural and pad-free
	check("The way is open." in run.overlay.banner, "room clear copy is 'The way is open.'")

	# Identify LEFT gate (seam) and RIGHT gate (gallery)
	var left_mouth_gate: PartyGate = null
	var right_mouth_gate: PartyGate = null
	for gate: PartyGate in mouth_gates:
		if gate.exit.side == RoomExit.Side.LEFT:
			left_mouth_gate = gate
		elif gate.exit.side == RoomExit.Side.RIGHT:
			right_mouth_gate = gate

	check(left_mouth_gate != null and left_mouth_gate.exit.target_id == &"glitter_seam",
		  "LEFT doorway targets Glitter Seam")
	check(right_mouth_gate != null and right_mouth_gate.exit.target_id == &"cracked_gallery",
		  "RIGHT doorway targets Cracked Gallery")

	# Travel through LEFT doorway into Glitter Seam
	travel(run, left_mouth_gate)
	await process_frame
	check(run.room.id == &"glitter_seam", "travelled through LEFT doorway into Glitter Seam")

	# Verify entry placement: party entered from RIGHT wall (opposite of LEFT exit)
	check(players[0].position.x > 300.0, "party placed near RIGHT wall just inside room")

	# Supply room exit is on BOTTOM wall and open
	check(run.gates().size() == 1, "glitter_seam has 1 exit gate")
	var seam_exit_gate: PartyGate = run.gates()[0]
	check(seam_exit_gate.exit.side == RoomExit.Side.BOTTOM, "seam exit is on BOTTOM wall")
	check(not seam_exit_gate.locked, "seam exit is open immediately (supply room)")

	# Travel down to Black Ledge
	travel(run, seam_exit_gate)
	await process_frame
	check(run.room.id == &"black_ledge", "travelled to Black Ledge boss room")

	# Verify entry placement: entered from TOP wall (opposite of BOTTOM exit)
	check(players[0].position.y < -100.0, "party placed near TOP wall in Black Ledge")

	# --- 6. Frostbreaker Keeps Black Ledge Exit Blocked -----------------
	check(run.gates().size() == 1, "Black Ledge has 1 exit gate")
	var boss_exit_gate: PartyGate = run.gates()[0]
	check(boss_exit_gate.locked, "Black Ledge exit is physically blocked while Frostbreaker is alive")
	travel(run, boss_exit_gate)
	check(run.room.id == &"black_ledge", "blocked exit refuses travel during boss fight")

	# Defeat Frostbreaker
	await clear_room(run)
	check(run.encounter.state == EncounterDirector.State.COMPLETE, "Frostbreaker defeated")
	check(not boss_exit_gate.locked, "Black Ledge exit unblocks when Frostbreaker is defeated")

	# Travel back home to town
	travel(run, boss_exit_gate)
	await process_frame
	check(run.room.kind == RoomDefinition.Kind.TOWN, "returned to Kelphollow town")
	check(run.journal.caves_cleared.size() == 1, "cave recorded as cleared")

	# Clean up
	run.free()
	print("DOORWAY & TRANSITION TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
