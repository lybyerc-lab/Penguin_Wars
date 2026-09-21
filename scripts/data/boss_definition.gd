class_name BossDefinition
extends Resource
## Data handle for the optional boss phase. A room's EncounterDefinition may
## name one; when it does, EncounterDirector runs a boss phase after the last
## wave and the room does not complete until the boss is down.
##
## SCALING CONTRACT — the one rule boss content must not break.
## Every combat value here is a BASE. After configure() returns,
## EncounterDirector multiplies the instance's health and damage by room
## difficulty (EncounterDefinition.difficulty_multiplier) and by the run's
## RunModifiers. Boss content must never apply either multiplier itself, or it
## lands twice. Party-size scaling is the exception: it belongs to the boss, so
## it lives here in scaled_health() and is applied during configure().
##
## The director reads only the architectural fields below. Everything else is a
## contract between this resource and the BossActor subclass that `scene`
## points at, so new boss content needs no director change.

# --- Architecture: read by EncounterDirector ---------------------------
@export var id: StringName = &"boss"
@export var display_name: String = "Boss"
## Must instance a BossActor. The director rejects anything else rather than
## leaving a room that can never be completed.
@export var scene: PackedScene
## Paid to every living penguin, through each one's own Harvest.
@export var reward: int = 15

# --- Base combat: read by BossActor.configure(), scaled by the director --
@export var maximum_health: float = 500.0
## Extra health per penguin beyond the first, as a fraction of the base.
@export_range(0.0, 4.0) var party_health_scaling: float = 0.65
## Base contact and projectile damage before room and run scaling.
@export var damage: float = 16.0

# --- Presentation: read by boss content and a boss HUD ------------------
@export var visual_scale: float = 1.8
@export var tint: Color = Color("ffcb77")
## Free for boss content to interpret — which attacks are available, how a bar
## is styled. Nothing in the architecture reads it.
@export_range(1, 9) var rank: int = 1

## The single home for party-size scaling. Boss content calls this rather than
## reimplementing the formula, so co-op scaling cannot drift between bosses.
func scaled_health(party_size: int) -> float:
	return maximum_health * (1.0 + party_health_scaling * float(maxi(0, party_size - 1)))
