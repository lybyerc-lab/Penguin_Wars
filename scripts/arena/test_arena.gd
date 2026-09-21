extends Node2D
## Composition root. Wires independent systems; no combat simulation here.
const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
const COLORS: Array[Color] = [Color("58dfed"), Color("ffcb77"), Color("bc9aff"), Color("a9e886")]
@export_range(1, 4) var player_count: int = 2
@onready var party: PartyRoster = $Party
@onready var encounter: EncounterDirector = $Encounter
@onready var progression: RunProgression = $Progression

func _ready() -> void:
	progression.party = party
	for index: int in range(player_count):
		var player := PLAYER_SCENE.instantiate() as PenguinPlayer
		player.identity = PlayerIdentity.new()
		player.identity.player_id = index + 1
		player.identity.local_slot = index
		player.identity.device_id = index
		player.identity.tint = COLORS[index]
		player.position = Vector2((index - (player_count - 1) * 0.5) * 80.0, 40.0)
		$Actors.add_child(player)
		if not party.register(player):
			push_error("Cannot register party member %d" % player.identity.player_id)
			player.queue_free()
			return
		progression.bind_player(player)
	$Camera.party = party
	encounter.party = party
	encounter.actor_root = $Actors
	encounter.enemy_defeated.connect(progression.reward_team)
	$HUD.party = party
	$HUD.encounter = encounter
	$HUD.progression = progression
	$HUD.setup()
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
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_B]:
			for player: PenguinPlayer in party.members():
				if player.identity.device_id == event.device:
					progression.choose(player.identity.player_id, 0 if event.button_index == JOY_BUTTON_A else 1)

func _draw() -> void:
	draw_style_box(_floor_style(), Rect2(-575, -295, 1150, 590))
	for x: int in range(-520, 560, 80):
		draw_line(Vector2(x, -260), Vector2(x, 260), Color(0.3, 0.7, 0.8, 0.08))
	for y: int in range(-240, 280, 80):
		draw_line(Vector2(-540, y), Vector2(540, y), Color(0.3, 0.7, 0.8, 0.08))
	draw_arc(Vector2.ZERO, 95, 0, TAU, 64, Color(0.4, 0.8, 0.9, 0.15), 2)

func _floor_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102d40")
	style.border_color = Color("376376")
	style.set_border_width_all(3)
	style.set_corner_radius_all(30)
	return style
