class_name BossDefinition
extends Resource
## Data handle for the optional boss phase. A room's EncounterDefinition may
## name one; when it does, EncounterDirector runs a boss phase after the last
## wave and the room does not complete until the boss is down.
##
## The director reads exactly three fields: `scene` (what to instance),
## `display_name` (what to call it) and `reward` (what to pay). Everything
## else here is a contract between this resource and the BossActor subclass
## that `scene` points at, and boss content is expected to add fields for its
## own needs. Nothing outside the boss lane should read those.

@export var id: StringName = &"boss"
@export var display_name: String = "Boss"
## Must instance a BossActor. The director rejects anything else rather than
## leaving a room that can never be completed.
@export var scene: PackedScene
## Paid to every living penguin, through each one's own Harvest.
@export var reward: int = 15
## Read by BossActor.configure(). Base health before party and run scaling.
@export var maximum_health: float = 500.0
## Extra health per penguin beyond the first, as a fraction of the base.
@export_range(0.0, 4.0) var party_health_scaling: float = 0.65
