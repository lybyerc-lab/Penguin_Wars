extends Node2D
## Composition root. Wires independent systems; no combat simulation here.
@export_range(1, 4) var player_count: int = 2
@export var mobile_preview: bool = false
## The room owns bounds, the spawn ring and prop placement.
@export var room: RoomDefinition = preload("res://resources/rooms/frostfall_arena.tres")
@onready var party: PartyRoster = $Party
@onready var encounter: EncounterDirector = $Encounter
@onready var progression: RunProgression = $Progression

func _ready() -> void:
	mobile_preview = mobile_preview or OS.has_feature("android") or "--mobile" in OS.get_cmdline_user_args()
	if mobile_preview:
		player_count = 1
	# Same wiring the town/cave expedition uses, so the two cannot drift apart.
	var session := RunSession.new()
	session.party = party
	session.wallet = $Wallet
	session.progression = progression
	session.encounter = encounter
	session.loot = $Loot
	session.builder = $Builder
	session.camera = $Camera
	session.actor_root = $Actors
	session.mobile = mobile_preview
	session.wire()
	if not session.spawn_party(player_count, room.entry_point):
		return
	$HUD.party = party
	$HUD.encounter = encounter
	$HUD.progression = progression
	$HUD.builder = $Builder
	$HUD.location = room.display_name
	RoomSpace.apply(room, party, encounter, $Builder, $Loot, $Camera, $IceArenaVisual, $Actors)
	if mobile_preview:
		$HUD.queue_free()
		var mobile_hud := MobileHUD.new()
		mobile_hud.name = "MobileHUD"
		mobile_hud.party = party
		mobile_hud.encounter = encounter
		mobile_hud.progression = progression
		mobile_hud.builder = $Builder
		add_child(mobile_hud)
		mobile_hud.setup()
	else:
		$HUD.setup()
	var boss_hud := BossHUD.new()
	boss_hud.name = "BossHUD"
	boss_hud.encounter = encounter
	boss_hud.party = party
	add_child(boss_hud)
	boss_hud.setup()
	encounter.start()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_R:
				get_tree().reload_current_scene()
			KEY_Q:
				progression.choose(1, 0)
			KEY_E:
				progression.choose(1, 1)
			KEY_ENTER:
				progression.choose(2, 0)
			KEY_SHIFT:
				progression.choose(2, 1)
			KEY_T:
				progression.choose(1, 2)
			KEY_PERIOD:
				progression.choose(2, 2)
			KEY_B:
				$Builder.build(1)
			KEY_N:
				$Builder.build(2)
			KEY_F:
				progression.toggle_ready(1)
			KEY_SLASH:
				progression.toggle_ready(2)
	elif event is InputEventJoypadButton and event.pressed:
		for player: PenguinPlayer in party.members():
			if player.identity.device_id == event.device:
				match event.button_index:
					JOY_BUTTON_Y:
						$Builder.build(player.identity.player_id)
					JOY_BUTTON_RIGHT_SHOULDER:
						progression.choose(player.identity.player_id, 2)
					JOY_BUTTON_START:
						progression.toggle_ready(player.identity.player_id)
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_B]:
			for player: PenguinPlayer in party.members():
				if player.identity.device_id == event.device:
					progression.choose(player.identity.player_id, 0 if event.button_index == JOY_BUTTON_A else 1)
