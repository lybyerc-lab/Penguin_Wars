class_name RunProgression
extends Node
## Arena policy: team XP, personal choices, no global pause during co-op.
signal choice_pending(player_id: int)
signal upgrade_applied(player_id: int, upgrade: UpgradeDefinition)
signal party_ready

const OPTIONS: Array[UpgradeDefinition] = [preload("res://resources/upgrades/sharp_ice.tres"), preload("res://resources/upgrades/swift_flippers.tres"), preload("res://resources/upgrades/harvest.tres"), preload("res://resources/upgrades/vitality.tres"), preload("res://resources/upgrades/armor.tres"), preload("res://resources/upgrades/regeneration.tres"), preload("res://resources/upgrades/might.tres"), preload("res://resources/upgrades/melee.tres"), preload("res://resources/upgrades/ranged.tres"), preload("res://resources/upgrades/haste.tres"), preload("res://resources/upgrades/precision.tres"), preload("res://resources/upgrades/evasion.tres"), preload("res://resources/upgrades/gathering.tres"), preload("res://resources/upgrades/engineering.tres"), preload("res://resources/upgrades/reach.tres")]
var party: PartyRoster
var pending: Dictionary = {}
var wallet: RunWallet
var purchases: Dictionary = {}
var encounter: EncounterDirector
var reserve: int = 0
var ready_players: Dictionary = {}
var _recipient_index: int = 0
var _paid_wave: int = 0
var in_town: bool = false

func begin_cave() -> void:
	_paid_wave = 0
	ready_players.clear()
	in_town = false

func bind_player(player: PenguinPlayer) -> void:
	pending[player.identity.player_id] = 0
	purchases[player.identity.player_id] = 0
	player.experience.leveled_up.connect(_on_level_up.bind(player.identity.player_id))

func _on_level_up(_level: int, player_id: int) -> void:
	pending[player_id] += 1
	choice_pending.emit(player_id)

func choose(player_id: int, option: int) -> bool:
	if option < 0 or option >= OPTIONS.size() or not shop_open():
		return false
	for player: PenguinPlayer in party.members(true):
		if player.identity.player_id == player_id:
			var free_choice: bool = pending.get(player_id, 0) > 0
			if not free_choice:
				if wallet == null or not wallet.try_spend(player_id, price(player_id, option)):
					return false
				purchases[player_id] = int(purchases.get(player_id, 0)) + 1
			player.apply_upgrade(OPTIONS[option])
			ready_players.erase(player_id)
			if free_choice:
				pending[player_id] -= 1
			upgrade_applied.emit(player_id, OPTIONS[option])
			return true
	return false

func price(player_id: int, option: int) -> int:
	if option < 0 or option >= OPTIONS.size():
		return 0
	return OPTIONS[option].snowflake_cost + int(purchases.get(player_id, 0)) * 3

func can_choose(player_id: int, option: int) -> bool:
	return shop_open() and option >= 0 and option < OPTIONS.size() and (pending.get(player_id, 0) > 0 or (wallet != null and wallet.balance(player_id) >= price(player_id, option)))

func shop_open() -> bool:
	return in_town or encounter == null or encounter.state in [EncounterDirector.State.INTERMISSION, EncounterDirector.State.COMPLETE]

func collect_materials(_collector_id: int, amount: int) -> void:
	var players: Array[PenguinPlayer] = party.members(true)
	if players.is_empty() or amount <= 0:
		return
	var bonus: int = mini(reserve, amount)
	reserve -= bonus
	for unit: int in range(amount + bonus):
		var player: PenguinPlayer = players[_recipient_index % players.size()]
		_recipient_index += 1
		_grant_income(player, 1)

func _grant_income(player: PenguinPlayer, amount: int) -> void:
	var income: int = player.stats.harvest_yield(amount)
	wallet.credit(player.identity.player_id, income)
	player.experience.grant(income)

func finish_wave(wave: int) -> void:
	if wave <= _paid_wave:
		return
	_paid_wave = wave
	ready_players.clear()
	for player: PenguinPlayer in party.members(true):
		_grant_income(player, 5)

func toggle_ready(player_id: int) -> void:
	if encounter == null or encounter.state != EncounterDirector.State.INTERMISSION:
		return
	var players: Array[PenguinPlayer] = party.members(true)
	var valid: bool = false
	for player: PenguinPlayer in players:
		valid = valid or player.identity.player_id == player_id
	if not valid:
		return
	ready_players[player_id] = not ready_players.get(player_id, false)
	for player: PenguinPlayer in players:
		if not ready_players.get(player.identity.player_id, false):
			return
	ready_players.clear()
	party_ready.emit()
