class_name PartyCamera
extends Camera2D
## Fixed room view: the combat floor fills the viewport, with HUD overlaid.
var party: PartyRoster
var mobile_layout: bool = false

func _ready() -> void:
	position = Vector2.ZERO
	offset = Vector2.ZERO
	zoom = Vector2.ONE
