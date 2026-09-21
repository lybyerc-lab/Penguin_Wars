class_name RunProgression
extends Node
## Arena policy: team XP, personal choices, no global pause during co-op.
signal choice_pending(player_id: int)
signal upgrade_applied(player_id: int, upgrade: UpgradeDefinition)

const OPTIONS: Array[UpgradeDefinition] = [preload("res://resources/upgrades/sharp_ice.tres"), preload("res://resources/upgrades/swift_flippers.tres")]
var party: PartyRoster
var pending: Dictionary = {}

func bind_player(player: PenguinPlayer) -> void:
	pending[player.identity.player_id] = 0
	player.experience.leveled_up.connect(_on_level_up.bind(player.identity.player_id))

func reward_team(_event: DamageEvent) -> void:
	for player: PenguinPlayer in party.members(true):
		player.experience.grant(1)

func _on_level_up(_level: int, player_id: int) -> void:
	pending[player_id] += 1
	choice_pending.emit(player_id)

func choose(player_id: int, option: int) -> bool:
	if option < 0 or option >= OPTIONS.size() or pending.get(player_id, 0) <= 0:
		return false
	for player: PenguinPlayer in party.members(true):
		if player.identity.player_id == player_id:
			player.apply_upgrade(OPTIONS[option])
			pending[player_id] -= 1
			upgrade_applied.emit(player_id, OPTIONS[option])
			return true
	return false
