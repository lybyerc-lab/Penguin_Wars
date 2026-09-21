extends Node2D
## Composition root. Wires independent systems; no combat simulation here.
const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
const COLORS: Array[Color] = [Color("58dfed"), Color("ffcb77"), Color("bc9aff"), Color("a9e886")]
@export_range(1, 4) var player_count: int = 2
@export var mobile_preview: bool = false
@onready var party: PartyRoster = $Party
@onready var encounter: EncounterDirector = $Encounter
@onready var progression: RunProgression = $Progression

func _ready() -> void:
	mobile_preview = mobile_preview or OS.has_feature("android") or "--mobile" in OS.get_cmdline_user_args()
	if mobile_preview:
		player_count = 1
	progression.party = party
	progression.wallet = $Wallet
	progression.encounter = encounter
	progression.party_ready.connect(encounter.advance_wave)
	for index: int in range(player_count):
		var player := PLAYER_SCENE.instantiate() as PenguinPlayer
		player.identity = PlayerIdentity.new()
		player.identity.player_id = index + 1
		player.identity.local_slot = index
		player.identity.device_id = index
		player.identity.tint = COLORS[index]
		if index % 2 == 1:
			player.get_node("Weapon").definition = preload("res://resources/weapons/fish_cleaver.tres")
		player.position = Vector2((index - (player_count - 1) * 0.5) * 80.0, 40.0)
		$Actors.add_child(player)
		if not party.register(player):
			push_error("Cannot register party member %d" % player.identity.player_id)
			player.queue_free()
			return
		progression.bind_player(player)
	$Camera.party = party
	$Camera.mobile_layout = mobile_preview
	encounter.party = party
	encounter.actor_root = $Actors
	$Loot.party = party
	$Loot.wallet = $Wallet
	$Loot.progression = progression
	$Loot.actor_root = $Actors
	$Loot.encounter = encounter
	encounter.loot_available.connect($Loot.enemy_drop)
	encounter.state_changed.connect($Loot.on_encounter_changed)
	encounter.wave_cleared.connect($Loot.bank_uncollected)
	encounter.wave_cleared.connect(progression.finish_wave)
	$HUD.party = party
	$HUD.encounter = encounter
	$HUD.progression = progression
	$Builder.party = party
	$Builder.wallet = $Wallet
	$Builder.actor_root = $Actors
	$Builder.encounter = encounter
	$HUD.builder = $Builder
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
	get_viewport().size_changed.connect(_resize_room)
	_resize_room()
	encounter.start()

func _resize_room() -> void:
	var size: Vector2 = get_viewport_rect().size
	# A small body inset keeps penguins fully visible at the screen edges.
	var floor_rect := Rect2(-size * 0.5, size)
	var actor_bounds: Rect2 = floor_rect.grow(-28)
	encounter.arena_bounds = actor_bounds
	$IceArenaVisual.floor_rect = floor_rect
	$IceArenaVisual.queue_redraw()
	for actor: Node in $Actors.get_children():
		if actor is PenguinPlayer or actor is ArenaEnemy:
			actor.arena_bounds = actor_bounds
		if actor is Node2D:
			actor.position = actor.position.clamp(actor_bounds.position, actor_bounds.end)

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
