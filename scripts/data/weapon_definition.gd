class_name WeaponDefinition
extends Resource
enum Pattern { SINGLE, ARC }
enum DamageKind { MELEE, RANGED }
@export var damage_kind: DamageKind = DamageKind.RANGED
## Shared immutable definition. Cooldowns and modifiers live on WeaponController.
@export var id: StringName
@export var display_name: String
## Immutable family and tier chain. Runtime progression replaces this Resource.
@export var family_id: StringName
@export_range(1, 4) var tier: int = 1
@export var next_tier: WeaponDefinition
@export var classes: Array[StringName] = []
@export_range(0.1, 1000.0) var damage: float = 14.0
@export_range(0.05, 10.0) var cooldown: float = 0.65
@export_range(10.0, 1000.0) var reach: float = 190.0
@export var pattern: Pattern = Pattern.SINGLE
@export_range(1.0, 360.0) var arc_degrees: float = 120.0
@export var knockback: float = 90.0
@export var tint: Color = Color("baf9ff")
@export var held_texture: Texture2D
@export var visual_scale: float = 0.56

func tier_label() -> String:
	return ["I", "II", "III", "IV"][tier - 1] if tier >= 1 and tier <= 4 else "?"

func is_max_tier() -> bool:
	return tier == 4

func can_merge_with(other: WeaponDefinition) -> bool:
	return other != null and family_id != &"" and family_id == other.family_id and tier == other.tier and not is_max_tier() and next_tier != null

func problems() -> PackedStringArray:
	var found := PackedStringArray()
	if id == &"":
		found.append("weapon has no id")
	if family_id == &"":
		found.append("weapon '%s' has no family" % id)
	if tier < 1 or tier > 4:
		found.append("weapon '%s' has an invalid tier" % id)
	var seen: Array[StringName] = []
	for class_id: StringName in classes:
		if class_id == &"" or not WeaponClasses.is_known(class_id) or seen.has(class_id):
			found.append("weapon '%s' has an invalid or duplicate class tag" % id)
			break
		seen.append(class_id)
	if tier < 4 and next_tier == null:
		found.append("weapon '%s' tier %d has no next tier" % [id, tier])
	if tier == 4 and next_tier != null:
		found.append("weapon '%s' tier IV has a next tier" % id)
	if next_tier != null:
		if next_tier.family_id != family_id or next_tier.tier != tier + 1:
			found.append("weapon '%s' has an invalid next tier" % id)
		elif next_tier.classes != classes:
			found.append("weapon '%s' changes classes across its tier chain" % id)
	return found
