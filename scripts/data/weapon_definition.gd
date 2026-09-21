class_name WeaponDefinition
extends Resource
enum Pattern { SINGLE, ARC }
enum DamageKind { MELEE, RANGED }
@export var damage_kind: DamageKind = DamageKind.RANGED
## Shared immutable definition. Cooldowns and modifiers live on WeaponController.
@export var id: StringName
@export var display_name: String
@export_range(0.1, 1000.0) var damage: float = 14.0
@export_range(0.05, 10.0) var cooldown: float = 0.65
@export_range(10.0, 1000.0) var reach: float = 190.0
@export var pattern: Pattern = Pattern.SINGLE
@export_range(1.0, 360.0) var arc_degrees: float = 120.0
@export var knockback: float = 90.0
@export var tint: Color = Color("baf9ff")
@export var held_texture: Texture2D
@export var visual_scale: float = 0.56
