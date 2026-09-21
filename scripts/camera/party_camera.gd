class_name PartyCamera
extends Camera2D
## Bounded arena: keep all living players visible, including extreme separation.
var party: PartyRoster

func _process(delta: float) -> void:
	if party == null:
		return
	var players: Array[PenguinPlayer] = party.members(true)
	if players.is_empty():
		return
	var bounds := Rect2(players[0].global_position, Vector2.ZERO)
	for player: PenguinPlayer in players:
		bounds = bounds.expand(player.global_position)
	var target: Vector2 = bounds.get_center() * 0.3
	position = position.lerp(target, 1.0 - exp(-5.0 * delta))
	# Reserve space for the HUD so actors cannot disappear underneath its cards.
	var viewport: Vector2 = get_viewport_rect().size
	var top_margin: float = 260.0 if party.members().size() > 2 else 160.0
	var bottom_margin: float = 40.0
	var usable := Vector2(viewport.x - 40.0, maxf(100.0, viewport.y - top_margin - bottom_margin))
	var required := Vector2(1240, 660) + position.abs() * 2.0
	var fit: float = minf(usable.x / required.x, usable.y / required.y)
	zoom = Vector2.ONE * fit
	offset = Vector2(0, -(top_margin - bottom_margin) * 0.5 / fit)
