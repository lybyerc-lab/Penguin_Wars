class_name RoomSpace
extends RefCounted
## Hands a room its own space. Before this, bounds, the spawn ring and prop
## placement were constants that assumed the original centered arena; every
## system now receives them from the room it is running in. No system reaches
## for a global current room — the composition root still does the wiring.

## Camera framing keeps a margin around the playable bounds.
const VIEW_MARGIN := Vector2(160, 140)

static func apply(room: RoomDefinition, party: PartyRoster = null, encounter: EncounterDirector = null, builder: CastleBuilder = null, loot: ArenaLoot = null, camera: PartyCamera = null, visual: RoomVisual = null, actor_root: Node = null) -> void:
	if room == null:
		return
	if party != null:
		for player: PenguinPlayer in party.members():
			player.arena_bounds = room.bounds
	if actor_root != null:
		# Enemies already in the room follow the new bounds too.
		for node: Node in actor_root.get_children():
			if node is ArenaEnemy:
				node.arena_bounds = room.bounds
				node.room_bounds = room.bounds
			elif node is SnowCastle:
				node.room_bounds = room.bounds
	if encounter != null:
		encounter.actor_bounds = room.bounds
		encounter.spawn_ring = room.spawn_ring
		encounter.spawn_center = room.bounds.get_center()
		# A room without its own encounter keeps whatever the scene configured.
		if room.encounter != null:
			encounter.definition = room.encounter
	if builder != null:
		builder.build_bounds = room.build_bounds()
		builder.room_bounds = room.bounds
	if loot != null:
		loot.supply_points = room.supply_points
	if camera != null:
		camera.framed_size = room.bounds.size + VIEW_MARGIN
	if visual != null:
		visual.bounds = room.bounds
		visual.palette = int(room.palette)
