class_name PlayerIdentity
extends Resource
## Stable run identity, independent of input device and eventual network owner.
@export_range(1, 4) var player_id: int = 1
@export var owner_peer_id: int = 1
@export_range(0, 3) var local_slot: int = 0
@export var device_id: int = -1
@export var tint: Color = Color("58dfed")
