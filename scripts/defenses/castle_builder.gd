class_name CastleBuilder
extends Node
const COST: int = 10
var party: PartyRoster
var wallet: RunWallet
var actor_root: Node2D
var encounter: EncounterDirector
var castles: Dictionary = {}
var last_result: Dictionary = {}

func has_castle(player_id: int) -> bool:
	return castles.has(player_id) and is_instance_valid(castles[player_id])

func build(player_id: int) -> bool:
	if has_castle(player_id) or encounter.state in [EncounterDirector.State.COMPLETE, EncounterDirector.State.FAILED]:
		return false
	for player: PenguinPlayer in party.members(true):
		if player.identity.player_id != player_id:
			continue
		var build_bounds: Rect2 = player.arena_bounds.grow(-40)
		var point: Vector2 = (player.global_position + player.dash.facing * 65).clamp(build_bounds.position, build_bounds.end)
		if point.distance_to(player.global_position) < 40:
			return _reject(player_id, "Face toward open ice")
		for node: Node in actor_root.get_children():
			if (node is SnowCastle or node is SupplySnowman) and node.global_position.distance_to(point) < 65:
				return _reject(player_id, "Move away from structures")
		if not wallet.try_spend(player_id, COST):
			return false
		var castle := SnowCastle.new()
		castle.party = party
		castle.player_id = player_id
		castle.tint = player.identity.tint
		castle.position = actor_root.to_local(point)
		actor_root.add_child(castle)
		castles[player_id] = castle
		last_result[player_id] = "Defense ready"
		return true
	return false

func _reject(player_id: int, message: String) -> bool:
	last_result[player_id] = message
	return false
