class_name TownMarket
extends Node
## Prices and effects for the town services. Services never touch a player
## directly: every purchase goes through the wallet and the player's own
## health, stat and weapon interfaces — the same seams the wave shop uses — so
## a later skill or item layer can hook the same places.

class Offer extends RefCounted:
	var id: StringName
	var label: String
	var detail: String
	var cost: int

	func _init(offer_id: StringName, offer_label: String, offer_detail: String, offer_cost: int) -> void:
		id = offer_id
		label = offer_label
		detail = offer_detail
		cost = offer_cost

const LANCE: WeaponDefinition = preload("res://resources/weapons/ice_lance.tres")
const CLEAVER: WeaponDefinition = preload("res://resources/weapons/fish_cleaver.tres")
## Fraction of maximum health a roused penguin stands up with.
const REVIVE_FRACTION: float = 0.4

var party: PartyRoster
var wallet: RunWallet
## Last message per player, shown on the service panel.
var notes: Dictionary = {}

func offers(kind: TownService.Kind) -> Array[Offer]:
	match kind:
		TownService.Kind.SHOP:
			return [
				Offer.new(&"herring", "Herring ration", "Restore 40 health", 4),
				Offer.new(&"packed_snow", "Packed snow", "+12 maximum health", 8),
				Offer.new(&"charm", "Traveller's charm", "+0.25 Harvest", 11),
			]
		TownService.Kind.NURSE:
			return [
				Offer.new(&"mend", "Warm compress", "Restore all health", 6),
				Offer.new(&"rouse", "Rouse a fallen friend", "Revive a downed penguin at 40%", 14),
				Offer.new(&"tonic", "Kelp tonic", "+0.4 regeneration", 10),
			]
		TownService.Kind.BLACKSMITH:
			return [
				Offer.new(&"hone", "Hone the edge", "+4 damage to every weapon", 9),
				Offer.new(&"rebalance", "Rebalance the haft", "+10% attack speed", 9),
				Offer.new(&"swap", "Trade weapon", "Lance for cleaver, or back", 6),
			]
		_:
			return []

func can_afford(player_id: int, offer: Offer) -> bool:
	return wallet != null and wallet.balance(player_id) >= offer.cost

func buy(player_id: int, kind: TownService.Kind, index: int) -> bool:
	var list: Array[Offer] = offers(kind)
	if index < 0 or index >= list.size() or wallet == null:
		return false
	var offer: Offer = list[index]
	var buyer: PenguinPlayer = _member(player_id)
	if buyer == null or not buyer.health.is_alive():
		return _reject(player_id, "Only a standing penguin can trade")
	# Checks that would waste the payment run before the wallet is touched.
	var patient: PenguinPlayer = null
	if offer.id == &"rouse":
		patient = _nearest_downed()
		if patient == null:
			return _reject(player_id, "Nobody needs rousing")
	if offer.id == &"mend" and buyer.health.current >= buyer.health.maximum:
		return _reject(player_id, "Already in good health")
	if not wallet.try_spend(player_id, offer.cost):
		return _reject(player_id, "Not enough snowflakes")
	match offer.id:
		&"herring":
			buyer.health.heal(40.0)
		&"packed_snow":
			buyer.health.maximum += 12.0
			buyer.health.heal(12.0)
		&"charm":
			buyer.stats.harvest_multiplier += 0.25
		&"mend":
			buyer.health.heal(buyer.health.maximum)
		&"rouse":
			patient.health.revive(patient.health.maximum * REVIVE_FRACTION)
		&"tonic":
			buyer.stats.regeneration += 0.4
		&"hone":
			buyer.stats.flat_weapon_damage += 4.0
		&"rebalance":
			buyer.stats.attack_speed += 10.0
		&"swap":
			buyer.weapon_rack.replace_weapon(0, CLEAVER if buyer.weapon_rack.weapon_at(0) == LANCE else LANCE)
	notes[player_id] = "%s — done" % offer.label
	return true

func note(player_id: int) -> String:
	return String(notes.get(player_id, ""))

func clear_note(player_id: int) -> void:
	notes.erase(player_id)

func _reject(player_id: int, message: String) -> bool:
	notes[player_id] = message
	return false

func _member(player_id: int) -> PenguinPlayer:
	if party == null:
		return null
	for player: PenguinPlayer in party.members():
		if player.identity.player_id == player_id:
			return player
	return null

func _nearest_downed() -> PenguinPlayer:
	if party == null:
		return null
	for player: PenguinPlayer in party.members():
		if not player.health.is_alive():
			return player
	return null
