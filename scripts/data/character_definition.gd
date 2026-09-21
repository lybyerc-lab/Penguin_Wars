class_name CharacterDefinition
extends Resource
## A selectable penguin. The run's roster is an ordered list of these; slot N
## takes roster[N]. A future selection screen replaces that list and nothing
## downstream changes, because the party is built from the roster rather than
## from hardcoded colours and weapon indices.
##
## A character that changes rules rather than numbers carries `traits`:
## CharacterTrait scenes added as children of the penguin at spawn. Player.gd
## stays generic — no character is ever named in it.

@export var id: StringName = &"penguin"
@export var display_name: String = "Penguin"
## Short, dry, in character. Shown wherever a penguin is picked.
@export var tagline: String = ""
@export var tint: Color = Color.WHITE
## Ordered loadout. Only slot 0 is wired today, because the penguin scene
## carries one weapon node; the array is the seam for multiple weapon slots.
@export var starting_weapons: Array[WeaponDefinition] = []
## Applied at spawn through the same seam the shop uses, so a character's
## opening stats need no special case anywhere.
@export var starting_stats: Array[UpgradeDefinition] = []
## Rule-changing components, instanced as children of the penguin at spawn.
## Each must instance a CharacterTrait.
@export var traits: Array[PackedScene] = []
## Scales the penguin's art only. It deliberately does NOT change the hitbox:
## how big a target a penguin is, is a balance decision, not a consequence of
## how it is drawn. A tiny penguin and a huge one both choose their own.
@export_range(0.25, 4.0) var body_scale: float = 1.0
## Scales the penguin's collision body. Independent of body_scale on purpose.
@export_range(0.25, 4.0) var collision_scale: float = 1.0
## When false, the id must appear in CampaignState.unlocked to be selectable.
@export var unlocked_by_default: bool = true

func selectable(campaign: CampaignState) -> bool:
	return unlocked_by_default or (campaign != null and campaign.is_unlocked(id))

## Everything wrong with this character, so a broken one fails a test rather
## than a run. Empty means playable.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	if id == &"":
		found.append("a character has no id")
	for weapon: WeaponDefinition in starting_weapons:
		if weapon == null:
			found.append("character '%s' has an empty weapon slot" % id)
	for upgrade: UpgradeDefinition in starting_stats:
		if upgrade == null:
			found.append("character '%s' has an empty starting stat" % id)
	for scene: PackedScene in traits:
		if scene == null:
			found.append("character '%s' has an empty trait slot" % id)
	return found
