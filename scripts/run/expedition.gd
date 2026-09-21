extends Node2D
## Run root for the town-and-caves loop. The party, wallets, stats, levels and
## purchase history live here and survive a room change; the room's own
## contents are swapped underneath. Combat, loot and defences are the same
## systems the arena slice uses — this adds places to use them in, not a second
## implementation of them.

## Horizontal spread when the town shows more than one cave mouth.
const MOUTH_SPACING: float = 520.0
## Screen space the route banner needs below the world. Service panels are
## deliberately not reserved for: they open while the party is up at the
## buildings, and the only thing they cover is the cave mouth below.
const PANEL_RESERVE: float = 84.0

@export_range(1, 4) var player_count: int = 2
## The place this run operates out of: one town and the caves reachable from it.
@export var region: RegionDefinition = preload("res://resources/regions/kelphollow.tres")
## Whole-run dials. Null means the identity default: no modifiers.
@export var modifiers: RunModifiers
## Ordered character selection for slots 1..4. Empty uses RunSession's default.
@export var roster: Array[CharacterDefinition] = []

@onready var party: PartyRoster = $Party
@onready var encounter: EncounterDirector = $Encounter
@onready var progression: RunProgression = $Progression
@onready var journal: RunJournal = $Journal
@onready var market: TownMarket = $Market

var session: RunSession
var room: RoomDefinition
var cave: CaveDefinition
## Swap for a persistent subclass to keep progress between runs.
var profile: ProfileStore
var campaign: CampaignState
var overlay: ExpeditionOverlay
var _gates: Array[PartyGate] = []
var _services: Array[TownService] = []
var _routed: bool = false

func _ready() -> void:
	if profile == null:
		profile = ProfileStore.new()
	campaign = profile.load_campaign()
	journal.campaign = campaign
	session = RunSession.new()
	if modifiers != null:
		session.modifiers = modifiers
	if not roster.is_empty():
		session.roster = roster
	session.party = party
	session.wallet = $Wallet
	session.progression = progression
	session.encounter = encounter
	session.loot = $Loot
	session.builder = $Builder
	session.camera = $Camera
	session.actor_root = $Actors
	session.wire()
	market.party = party
	market.wallet = $Wallet
	var problems: PackedStringArray = region.problems() if region != null else PackedStringArray(["no region"])
	if not problems.is_empty():
		push_error("Region is unplayable: %s" % ", ".join(problems))
		return
	if not session.spawn_party(player_count, region.town.entry_point):
		return
	$Camera.bottom_reserve = 0.0
	$HUD.party = party
	$HUD.encounter = encounter
	$HUD.progression = progression
	$HUD.builder = $Builder
	$HUD.setup()
	var boss_hud := BossHUD.new()
	boss_hud.name = "BossHUD"
	boss_hud.encounter = encounter
	boss_hud.party = party
	add_child(boss_hud)
	boss_hud.setup()
	overlay = ExpeditionOverlay.new()
	overlay.name = "Overlay"
	overlay.party = party
	overlay.market = market
	overlay.journal = journal
	add_child(overlay)
	overlay.setup()
	encounter.completed.connect(_on_room_cleared)
	encounter.state_changed.connect(_on_encounter_state)
	enter_town()

# --- places -------------------------------------------------------------

func enter_town() -> void:
	cave = null
	_load_room(region.town)
	_services = TownHub.build($Places, party)
	overlay.services = _services
	var mouths: Array[CaveDefinition] = region.caves
	for index: int in range(mouths.size()):
		var spec := RoomExit.new()
		spec.target_id = mouths[index].id
		spec.label = mouths[index].display_name
		spec.hint = mouths[index].signpost
		spec.side = RoomExit.Side.BOTTOM
		spec.position = Vector2((index - (mouths.size() - 1) * 0.5) * MOUTH_SPACING, 165.0)
		var gate: PartyGate = _add_gate(spec)
		gate.locked = false
		gate.place_at_wall(room.bounds)
	var doors: Array[Dictionary] = []
	for gate: PartyGate in _gates:
		if gate.exit != null:
			doors.append({
				"side": gate.exit.side,
				"position": gate.position,
				"target_id": gate.exit.target_id,
			})
	$Backdrop.doorways = doors
	overlay.banner = "Step up to a building to trade.  Head through a passage to set out."

func enter_cave(target: CaveDefinition) -> void:
	cave = target
	journal.begin_expedition(cave)
	_enter_room(cave.entrance())

func _enter_room(next: RoomDefinition, entry_side: int = -1) -> void:
	if next == null:
		return
	_load_room(next, entry_side)
	for spec: RoomExit in next.exits:
		var gate: PartyGate = _add_gate(spec)
		gate.locked = next.has_encounter()
		gate.place_at_wall(next.bounds)
	if next.has_encounter():
		encounter.start()
	else:
		# A room with no fight still stocks its supplies; nothing else would.
		$Loot.resupply()
	overlay.banner = next.arrival_line

## Everything a room change resets. Players are deliberately not touched: their
## health, stats, levels and wallets are the run, not the room.
func _load_room(next: RoomDefinition, entry_side: int = -1) -> void:
	room = next
	_routed = false
	encounter.reset()
	session.clear_room_actors()
	for node: Node in $Places.get_children():
		$Places.remove_child(node)
		node.queue_free()
	_gates.clear()
	_services.clear()
	overlay.services = _services
	progression.begin_room()
	# Town has no encounter, so the shop opens on this flag instead of a state.
	progression.in_town = room.kind == RoomDefinition.Kind.TOWN
	$Loot.begin_room()
	RoomSpace.apply(room, party, encounter, $Builder, $Loot, $Camera, $Backdrop, $Actors)
	var entry: Vector2 = room.entry_point
	if entry_side >= 0:
		entry = _entry_from_side(entry_side, room.bounds)
	session.place_party(entry)
	$HUD.location = room.display_name
	var banner := LocationBanner.new()
	banner.location_name = room.display_name
	banner.wide_party = party.members().size() > 2
	overlay.add_child(banner)

## Compute a spawn position just inside the room from the given wall side.
## The party appears ~80px inward from the wall edge so they are clearly
## inside the room, not stuck at the threshold.
func _entry_from_side(s: int, bounds: Rect2) -> Vector2:
	var center: Vector2 = bounds.get_center()
	var inset: float = 80.0
	match s:
		RoomExit.Side.LEFT:
			return Vector2(bounds.position.x + inset, center.y)
		RoomExit.Side.RIGHT:
			return Vector2(bounds.end.x - inset, center.y)
		RoomExit.Side.TOP:
			return Vector2(center.x, bounds.position.y + inset)
		RoomExit.Side.BOTTOM:
			return Vector2(center.x, bounds.end.y - inset)
	return center

## LEFT↔RIGHT, TOP↔BOTTOM. Used to determine which side the party enters
## the next room from, given the side they left the current room through.
func _opposite_side(s: int) -> int:
	match s:
		RoomExit.Side.LEFT:
			return RoomExit.Side.RIGHT
		RoomExit.Side.RIGHT:
			return RoomExit.Side.LEFT
		RoomExit.Side.TOP:
			return RoomExit.Side.BOTTOM
		RoomExit.Side.BOTTOM:
			return RoomExit.Side.TOP
	return s

func _add_gate(spec: RoomExit) -> PartyGate:
	var gate := PartyGate.new()
	gate.exit = spec
	gate.party = party
	gate.position = spec.position
	gate.travelled.connect(_on_gate_travelled)
	$Places.add_child(gate)
	_gates.append(gate)
	return gate

## Hand campaign state to the profile store. The in-memory default returns
## false, so a caller can tell a real save from a held one.
func save_profile() -> bool:
	return profile.save_campaign(campaign) if profile != null else false

## The current room's gates and buildings. The expedition owns both lists; the
## overlay and the tests read them rather than searching the tree.
func gates() -> Array[PartyGate]:
	return _gates

func services() -> Array[TownService]:
	return _services

func _unlock_gates() -> void:
	for gate: PartyGate in _gates:
		if is_instance_valid(gate):
			gate.locked = false

# --- transitions --------------------------------------------------------

func _on_gate_travelled(gate: PartyGate) -> void:
	var spec: RoomExit = gate.exit
	if spec == null:
		return
	var opposite: int = _opposite_side(spec.side)
	# A town exit names a cave; a cave exit names a room inside that cave.
	if room.kind == RoomDefinition.Kind.TOWN:
		var chosen: CaveDefinition = region.cave(spec.target_id)
		if chosen == null:
			push_error("Region %s has no cave named %s" % [region.id, spec.target_id])
			return
		enter_cave(chosen)
		return
	if spec.leads_outside():
		journal.record_cave(cave)
		save_profile()
		enter_town()
		return
	var next: RoomDefinition = cave.room(spec.target_id)
	if next == null:
		push_error("Cave %s has no room named %s" % [cave.id, spec.target_id])
		return
	_enter_room(next, opposite)

func _on_room_cleared() -> void:
	journal.record_room(room)
	_unlock_gates()
	overlay.banner = "%s is clear.  The way is open." % room.display_name

func _on_encounter_state() -> void:
	if encounter.state != EncounterDirector.State.FAILED or _routed:
		return
	_routed = true
	journal.record_rout()
	save_profile()
	overlay.banner = "The party went down in %s.  R starts a new run." % room.display_name

# --- input --------------------------------------------------------------

## In a service zone the upgrade keys buy from that service; everywhere else
## they pick wave-shop upgrades, exactly as in the arena slice.
func _option(player_id: int, index: int) -> void:
	var service: TownService = overlay.service_at(player_id) if overlay != null else null
	if service != null:
		if service.kind != TownService.Kind.TOWN_HALL:
			market.buy(player_id, service.kind, index)
		return
	progression.choose(player_id, index)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_R:
				get_tree().reload_current_scene()
			KEY_Q:
				_option(1, 0)
			KEY_E:
				_option(1, 1)
			KEY_T:
				_option(1, 2)
			KEY_ENTER:
				_option(2, 0)
			KEY_SHIFT:
				_option(2, 1)
			KEY_PERIOD:
				_option(2, 2)
			KEY_B:
				$Builder.build(1)
			KEY_N:
				$Builder.build(2)
			KEY_F:
				progression.toggle_ready(1)
			KEY_SLASH:
				progression.toggle_ready(2)
	elif event is InputEventJoypadButton and event.pressed:
		for player: PenguinPlayer in party.members():
			if player.identity.device_id != event.device:
				continue
			var id: int = player.identity.player_id
			match event.button_index:
				JOY_BUTTON_A:
					_option(id, 0)
				JOY_BUTTON_B:
					_option(id, 1)
				JOY_BUTTON_RIGHT_SHOULDER:
					_option(id, 2)
				JOY_BUTTON_Y:
					$Builder.build(id)
				JOY_BUTTON_START:
					progression.toggle_ready(id)
