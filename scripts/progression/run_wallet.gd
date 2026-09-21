class_name RunWallet
extends Node
## Run-scoped currency with selectable co-op ownership; no persistent progression.
signal changed
@export var shared: bool = false
var _balances: Dictionary = {}

func _key(player_id: int) -> int:
	return 0 if shared else player_id

func balance(player_id: int) -> int:
	return int(_balances.get(_key(player_id), 0))

func credit(player_id: int, amount: int) -> void:
	if player_id < 1 or player_id > 4 or amount <= 0:
		return
	var key: int = _key(player_id)
	_balances[key] = balance(player_id) + amount
	changed.emit()

func try_spend(player_id: int, amount: int) -> bool:
	if player_id < 1 or player_id > 4 or amount <= 0 or balance(player_id) < amount:
		return false
	_balances[_key(player_id)] = balance(player_id) - amount
	changed.emit()
	return true
