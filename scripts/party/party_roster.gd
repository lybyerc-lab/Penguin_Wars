class_name PartyRoster
extends Node

signal member_added(player: PenguinPlayer)
signal member_removed(player_id: int)

const MAX_PLAYERS: int = 4
var _members: Dictionary = {}

func register(player: PenguinPlayer) -> bool:
	var id: int = player.identity.player_id
	if id < 1 or id > MAX_PLAYERS or _members.has(id) or _members.size() >= MAX_PLAYERS:
		return false
	_members[id] = player
	player.tree_exiting.connect(unregister.bind(id), CONNECT_ONE_SHOT)
	member_added.emit(player)
	return true

func unregister(id: int) -> void:
	if _members.erase(id):
		member_removed.emit(id)

func members(alive_only: bool = false) -> Array[PenguinPlayer]:
	var result: Array[PenguinPlayer] = []
	for id: int in _members:
		var player: PenguinPlayer = _members[id]
		if is_instance_valid(player) and (not alive_only or player.health.is_alive()):
			result.append(player)
	return result

func nearest_alive(origin: Vector2) -> PenguinPlayer:
	var nearest: PenguinPlayer
	var best: float = INF
	for player: PenguinPlayer in members(true):
		var distance: float = origin.distance_squared_to(player.global_position)
		if distance < best:
			best = distance
			nearest = player
	return nearest
