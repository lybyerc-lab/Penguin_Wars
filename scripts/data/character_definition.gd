class_name CharacterDefinition
extends Resource
## A selectable penguin. The run's roster is an ordered list of these; slot N
## takes roster[N]. A future selection screen replaces that list and nothing
## downstream changes, because the party is built from the roster rather than
## from hardcoded colours and weapon indices.

@export var id: StringName = &"penguin"
@export var display_name: String = "Penguin"
## Explicit per character; the neutral default makes an unset tint obvious.
@export var tint: Color = Color.WHITE
## Null keeps whatever the player scene already carries.
@export var starting_weapon: WeaponDefinition
## When false, the id must appear in CampaignState.unlocked to be selectable.
@export var unlocked_by_default: bool = true

func selectable(campaign: CampaignState) -> bool:
	return unlocked_by_default or (campaign != null and campaign.is_unlocked(id))
