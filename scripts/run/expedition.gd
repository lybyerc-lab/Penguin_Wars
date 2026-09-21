extends Node2D
## Run root for the town-and-caves loop. The party, wallets, stats, levels and
## purchase history live here and survive a room change; the room's own
## contents are swapped underneath. Combat, loot and defences are the same
## systems the arena slice uses — this adds places to use them in, not a second
## implementation of them.

const TOWN_ROOM: RoomDefinition = preload("res://resources/rooms/penguin_town.tres")
const CAVES: Array[CaveDefinition] = [preload("res://resources/caves/hollow_shelf.tres")]
## Horizontal spread when the town shows more than one cave mouth.
const MOUTH_SPACING: float = 520.0
## Screen space the route banner needs below the world. Service panels are
## deliberately not reserved for: they open while the party is up at the
## buildings, and the only thing they cover is the cave mouth below.
const PANEL_RESERVE: float = 84.0

@export_range(1, 4) var player_count: int = 2

@onready var party: PartyRoster = $Party
@onready var encounter: EncounterDirector = $Encounter
@onready var progression: RunProgression = $Progression
@onready var journal: RunJournal = $Journal
@onready var market: TownMarket = $Market

var session: RunSession
var room: RoomDefinition
var cave: CaveDefinition
var overlay: ExpeditionOverlay
var _gates: Array[PartyGate] = []
var _services: Array[TownService] = []
var _routed: bool = false

func _ready() -> void:
	session = RunSession.new()
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
	if not session.spawn_party(player_count, TOWN_ROOM.entry_point):
		return
	$Camera.bottom_reserve = PANEL_RESERVE
	$HUD.party = party
	$HUD.encounter = encounter
	$HUD.progression = progression
	$HUD.builder = $Builder
	$HUD.setup()
	overlay = ExpeditionOverlay.new()
	overlay.name = "Overlay"
	overlay.party = party
	overlay.market = market
	overlay.journal = journal
	add_child(overlay)
	overlay.setup()
	var boss_hud := BossHUD.new()
	boss_hud.name = "BossHUD"
	boss_hud.encounter = encounter
	boss_hud.party = party
	add_child(boss_hud)
	boss_hud.setup()
	encounter.completed.connect(_on_room_cleared)
	encounter.state_changed.connect(_on_encounter_state)
	enter_town()

# --- places -------------------------------------------------------------

func enter_town() -> void:
	cave = null
	_load_room(TOWN_ROOM)
	_services = TownHub.build($Places, party)
	overlay.services = _services
	for index: int in range(CAVES.size()):
		var spec := RoomExit.new()
		spec.target_id = CAVES[index].id
		spec.label = CAVES[index].display_name
		spec.hint = CAVES[index].signpost
		spec.position = Vector2((index - (CAVES.size() - 1) * 0.5) * MOUTH_SPACING, 165.0)
		_add_gate(spec).locked = false
	overlay.banner = "Step up to a building to trade.  Gather the whole party on a cave mouth to set out."

func enter_cave(target: CaveDefinition) -> void:
	cave = target
	journal.begin_expedition(cave)
	_enter_room(cave.entrance())

func _enter_room(next: RoomDefinition) -> void:
	if next == null:
		return
	_load_room(next)
	for spec: RoomExit in next.exits:
		var gate: PartyGate = _add_gate(spec)
		gate.locked = next.has_encounter()
	if next.has_encounter():
		encounter.start()
	else:
		# A room with no fight still stocks its supplies; nothing else would.
		$Loot.resupply()
	overlay.banner = next.arrival_line

## Everything a room change resets. Players are deliberately not touched: their
## health, stats, levels and wallets are the run, not the room.
func _load_room(next: RoomDefinition) -> void:
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
	session.place_party(room.entry_point)
	$HUD.location = room.display_name
	var banner := LocationBanner.new()
	banner.location_name = room.display_name
	banner.wide_party = party.members().size() > 2
	overlay.add_child(banner)

func _add_gate(spec: RoomExit) -> PartyGate:
	var gate := PartyGate.new()
	gate.exit = spec
	gate.party = party
	gate.position = spec.position
	gate.travelled.connect(_on_gate_travelled)
	$Places.add_child(gate)
	_gates.append(gate)
	return gate

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
	# A town exit names a cave; a cave exit names a room inside that cave.
	if room.kind == RoomDefinition.Kind.TOWN:
		for candidate: CaveDefinition in CAVES:
			if candidate.id == spec.target_id:
				enter_cave(candidate)
				return
		push_error("Town has no cave named %s" % spec.target_id)
		return
	if spec.leads_outside():
		journal.record_cave(cave)
		enter_town()
		return
	var next: RoomDefinition = cave.room(spec.target_id)
	if next == null:
		push_error("Cave %s has no room named %s" % [cave.id, spec.target_id])
		return
	_enter_room(next)

func _on_room_cleared() -> void:
	journal.record_room(room)
	_unlock_gates()
	overlay.banner = "%s is clear.  Gather on a route to move on." % room.display_name

func _on_encounter_state() -> void:
	if encounter.state != EncounterDirector.State.FAILED or _routed:
		return
	_routed = true
	journal.record_rout()
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
