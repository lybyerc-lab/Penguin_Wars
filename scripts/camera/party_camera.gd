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
## Optional Township-only point of interest. The expedition sets this from an
## active service pad and clears it as soon as the party leaves.
var focus_active: bool = false
var focus_point := Vector2.ZERO
var focus_framed_size := Vector2(1240, 680)

func set_focus(world_point: Vector2) -> void:
	focus_active = true
	focus_point = world_point

func clear_focus() -> void:
	focus_active = false

func _process(delta: float) -> void:
	if party == null:
		return
	var players: Array[PenguinPlayer] = party.members(true)
	if players.is_empty():
		return
	var bounds := Rect2(players[0].global_position, Vector2.ZERO)
	for player: PenguinPlayer in players:
		bounds = bounds.expand(player.global_position)
	var framing_bounds := bounds
	if follow_party and focus_active:
		framing_bounds = framing_bounds.expand(focus_point)
	var target: Vector2 = bounds.get_center() if follow_party else bounds.get_center() * 0.3
	if follow_party and focus_active:
		# Keep nearby players in frame while giving the entrance more weight.
		target = framing_bounds.get_center().lerp(focus_point, 0.35)
	position = position.lerp(target, 1.0 - exp(-5.0 * delta))
	var viewport: Vector2 = get_viewport_rect().size

	# Mobile HUD and touch controls deliberately overlay the world. Reserving
	# large strips above and below the camera made the actual playable world
	# shrink into the middle of wide phones. Keep only the ordinary safe pad so
	# gameplay uses the full display; UI safe areas are handled by the controls.
	var top_margin: float = 0.0
	var bottom_margin: float = 0.0 if mobile_layout else bottom_reserve
	var safe_pad := Vector2(24.0, 20.0)
	var usable := Vector2(viewport.x - safe_pad.x, maxf(100.0, viewport.y - top_margin - bottom_margin - safe_pad.y))
	var required: Vector2
	if follow_party and focus_active:
		required = focus_framed_size.max(framing_bounds.size + Vector2(260, 180))
	elif follow_party:
		required = framed_size.max(bounds.size + Vector2(260, 180))
	else:
		required = framed_size + position.abs() * 2.0
	var fit: float = minf(usable.x / required.x, usable.y / required.y)
	fit = minf(fit, 1.0)
	var target_zoom := Vector2.ONE * fit
	var target_offset := Vector2(0, -(top_margin - bottom_margin) * 0.5 / fit)
	if follow_party:
		var ease: float = 1.0 - exp(-4.0 * delta)
		zoom = zoom.lerp(target_zoom, ease)
		offset = offset.lerp(target_offset, ease)
	else:
		zoom = target_zoom
		offset = target_offset
