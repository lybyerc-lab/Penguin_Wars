extends CharacterTrait
## Test-only rule. It proves a character can change how a penguin behaves
## without Player.gd knowing that any character exists — no boss, no named
## character, no special case anywhere in the actor.

var setups: int = 0
var speed_before: float = 0.0

func setup(owner_player: PenguinPlayer) -> void:
	super.setup(owner_player)
	setups += 1
	speed_before = owner_player.speed
	owner_player.speed *= 2.0
	owner_player.stats.armor += 5.0
