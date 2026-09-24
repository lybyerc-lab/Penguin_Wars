class_name PartyCamera
extends Camera2D
## Bounded arena: keep all living players visible, including extreme separation.
var party: PartyRoster
var mobile_layout: bool = false
## Room-owned area the camera must keep on screen.
var framed_size := Vector2(1240, 660)
## Screen space a scene needs below the world, for panels drawn over it.
var bottom_reserve: float = 0.0
## Large outdoor spaces follow the party instead of fitting the whole room.
var follow_party: bool = false

func _process(delta: float) -> void:
	if party == null:
		return
	var players: Array[PenguinPlayer] = party.members(true)
	if players.is_empty():
		return
	var bounds := Rect2(players[0].global_position, Vector2.ZERO)
	for player: PenguinPlayer in players:
		bounds = bounds.expand(player.global_position)
	var target: Vector2 = bounds.get_center() if follow_party else bounds.get_center() * 0.3
	position = position.lerp(target, 1.0 - exp(-5.0 * delta))
	var viewport: Vector2 = get_viewport_rect().size
	var top_margin: float = 0.0
	var bottom_margin: float = bottom_reserve
	if mobile_layout:
		top_margin = 140.0
		bottom_margin = 55.0
	var safe_pad := Vector2(24.0, 20.0)
	var usable := Vector2(viewport.x - safe_pad.x, maxf(100.0, viewport.y - top_margin - bottom_margin - safe_pad.y))
	var required: Vector2 = framed_size.max(bounds.size + Vector2(260, 180)) if follow_party else framed_size + position.abs() * 2.0
	var fit: float = minf(usable.x / required.x, usable.y / required.y)
	fit = minf(fit, 1.0)
	zoom = Vector2.ONE * fit
	offset = Vector2(0, -(top_margin - bottom_margin) * 0.5 / fit)
