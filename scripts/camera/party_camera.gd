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
	# Fit full arena plus margins and camera offset; never crop a distant player.
	var viewport: Vector2 = get_viewport_rect().size
	var required := Vector2(1200, 700) + position.abs() * 2.0
	var fit: float = minf(viewport.x / required.x, viewport.y / required.y)
	zoom = Vector2.ONE * fit
