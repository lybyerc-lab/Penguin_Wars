class_name DiscoveryDefinition
extends Resource

enum Kind { WEAPON_CACHE, RISK_HOARD }
@export var id: StringName
@export var kind: Kind
@export var position: Vector2
@export var closed_texture: Texture2D
@export var open_texture: Texture2D
@export var ring_offset := Vector2(0, 8)
@export var dig_radius: float = 72.0
@export var dig_time: float = 1.5
@export var glint_offset := Vector2(58, -92)
@export var extra_glint_offsets: PackedVector2Array
@export var hint: String = ""
@export var reward_weapon: WeaponDefinition
@export var salvage_snow: int = 30
@export var mound_positions: PackedVector2Array
@export var ambush: Array[PackedScene] = []
@export var ambush_positions: PackedVector2Array
@export var reward_snow: int = 15
@export var reward_health: int = 25
