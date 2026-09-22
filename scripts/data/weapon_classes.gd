class_name WeaponClasses
extends RefCounted
## Canonical stable tags for weapon data, aggregation and future shop weighting.

const FISH: StringName = &"fish"
const BLADE: StringName = &"blade"
const HARPOON: StringName = &"harpoon"
const SNOW: StringName = &"snow"
const ICE: StringName = &"ice"
const HEAVY: StringName = &"heavy"
const PRECISION: StringName = &"precision"
const ENGINEERING: StringName = &"engineering"
const SUPPORT: StringName = &"support"
const ROYAL: StringName = &"royal"
const SWIFT: StringName = &"swift"
const EXPLOSIVE: StringName = &"explosive"

const ALL: Array[StringName] = [FISH, BLADE, HARPOON, SNOW, ICE, HEAVY, PRECISION, ENGINEERING, SUPPORT, ROYAL, SWIFT, EXPLOSIVE]

static func is_known(class_id: StringName) -> bool:
	return ALL.has(class_id)
