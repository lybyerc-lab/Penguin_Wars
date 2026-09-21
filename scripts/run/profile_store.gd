class_name ProfileStore
extends RefCounted
## The seam for permanent progression. The default keeps one CampaignState in
## memory for the lifetime of the process, so a run behaves exactly as it does
## with no save system at all.
##
## To add saving, subclass and override the two methods — a file-backed store
## is ResourceLoader.load() and ResourceSaver.save() over CampaignState — and
## hand the subclass to Expedition. Nothing else in the game changes, because
## nothing else knows where campaign state comes from.

var _campaign: CampaignState = CampaignState.new()

func load_campaign() -> CampaignState:
	return _campaign

## Returns whether the state reached durable storage. The in-memory default
## returns false, so a caller can tell "saved" from "held".
func save_campaign(state: CampaignState) -> bool:
	_campaign = state
	return false

## Whether this store survives a restart. Used by UI that should not promise
## a player their progress is kept.
func is_persistent() -> bool:
	return false
