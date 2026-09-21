class_name BossDefinition
extends Resource
## Shared immutable boss data. Scaling for party size and room difficulty is
## applied to the instance by ArenaBoss.configure(), never to this resource.

@export var display_name: String = "Frostbreaker"
@export var maximum_health: float = 500.0
@export var damage: float = 16.0
@export var visual_scale: float = 1.8
@export var tint: Color = Color("ffcb77")
## 1 charges only; 2 adds a radial volley; 3 adds a slam and an enrage.
@export_range(1, 3) var rank: int = 1
@export var reward: int = 15
