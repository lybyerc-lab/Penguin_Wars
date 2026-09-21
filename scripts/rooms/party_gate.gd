class_name PartyGate
extends Node2D
## A way out of a room. Travel is positional and shared: every living penguin
## enters the doorway together, so branching adds no new input binding and one
## player cannot drag the party through a door alone.
##
## Presentation: a rectangular passage cut into the room wall, inspired by
## classic top-down Zelda dungeons.

signal travelled(gate: PartyGate)

## Doorway threshold dimensions: 90px deep into room × 130px wide/tall along wall.
const THRESHOLD_DEPTH: float = 90.0
const THRESHOLD_WIDTH: float = 130.0
## Deliberate dwell time for passing through a doorway.
const DWELL: float = 0.4
## Visual depth of the passage "tunnel" drawn beyond the room edge.
const PASSAGE_DEPTH: float = 50.0
## Width reserved for caption text.
const CAPTION_WIDTH: float = 360.0
## Pillar width flanking the passage opening.
const PILLAR_WIDTH: float = 14.0

var exit: RoomExit
var party: PartyRoster
var locked: bool = true:
	set(value):
		locked = value
		queue_redraw()
var lock_reason: String = "Clear the room first"
var dwell: float = 0.0
var spent: bool = false
## Set by place_at_wall(); the threshold rectangle in local coordinates.
var threshold := Rect2(-65, -45, 130, 90)
## Procedural open transition (0.0 = fully barricaded, 1.0 = fully open passage).
var open_ratio: float = 0.0

func _ready() -> void:
	z_index = -2
	open_ratio = 0.0 if locked else 1.0

func label() -> String:
	return exit.label if exit != null else "Onward"

func hint() -> String:
	return exit.hint if exit != null else ""

func side() -> int:
	return exit.side if exit != null else RoomExit.Side.BOTTOM

func is_horizontal() -> bool:
	var s: int = side()
	return s == RoomExit.Side.LEFT or s == RoomExit.Side.RIGHT

## Position this gate flush against the specified room boundary wall.
## Threshold rectangle is oriented to extend THRESHOLD_DEPTH into the room
## and THRESHOLD_WIDTH along the wall.
func place_at_wall(bounds: Rect2) -> void:
	if exit == null:
		return
	position = RoomExit.wall_position(bounds, exit.side)
	match exit.side:
		RoomExit.Side.LEFT:
			# Wall at left; threshold extends into the room to the right (+x).
			threshold = Rect2(-15.0, -THRESHOLD_WIDTH * 0.5, THRESHOLD_DEPTH + 15.0, THRESHOLD_WIDTH)
		RoomExit.Side.RIGHT:
			# Wall at right; threshold extends into the room to the left (-x).
			threshold = Rect2(-THRESHOLD_DEPTH, -THRESHOLD_WIDTH * 0.5, THRESHOLD_DEPTH + 15.0, THRESHOLD_WIDTH)
		RoomExit.Side.TOP:
			# Wall at top; threshold extends into the room downwards (+y).
			threshold = Rect2(-THRESHOLD_WIDTH * 0.5, -15.0, THRESHOLD_WIDTH, THRESHOLD_DEPTH + 15.0)
		RoomExit.Side.BOTTOM:
			# Wall at bottom; threshold extends into the room upwards (-y).
			threshold = Rect2(-THRESHOLD_WIDTH * 0.5, -THRESHOLD_DEPTH, THRESHOLD_WIDTH, THRESHOLD_DEPTH + 15.0)

## Count of living party members inside the threshold rectangle.
func standing() -> int:
	if party == null:
		return 0
	var count: int = 0
	for player: PenguinPlayer in party.members(true):
		var local: Vector2 = player.global_position - global_position
		if threshold.has_point(local):
			count += 1
	return count

## Living penguins still needed in the threshold.
func missing() -> int:
	if party == null:
		return 0
	return maxi(0, party.members(true).size() - standing())

func progress() -> float:
	return clampf(dwell / DWELL, 0.0, 1.0)

func _physics_process(delta: float) -> void:
	# Animate procedural opening/closing when combat clears.
	if not locked and open_ratio < 1.0:
		open_ratio = minf(1.0, open_ratio + delta * 3.0)
		queue_redraw()
	elif locked and open_ratio > 0.0:
		open_ratio = maxf(0.0, open_ratio - delta * 3.0)
		queue_redraw()

	if spent or party == null:
		return

	var living: int = party.members(true).size()
	if locked or living == 0 or standing() < living:
		# Decay quickly so stepping off clearly cancels the departure.
		dwell = maxf(0.0, dwell - delta * 2.5)
	else:
		dwell += delta
		if dwell >= DWELL:
			spent = true
			travelled.emit(self)
	queue_redraw()

# --- drawing ------------------------------------------------------------

func _draw() -> void:
	var s: int = side()
	var accent: Color = Color("5a6b7d") if locked else Color("7fe0c4")
	_draw_passage(s)
	_draw_captions(s, accent)

func _draw_passage(s: int) -> void:
	var target: StringName = exit.target_id if exit != null else &""
	var is_glitter: bool = target == &"glitter_seam"
	var is_cracked: bool = target == &"cracked_gallery"

	# Tunnel depth box extending into the wall / beyond room boundary.
	var tunnel_rect: Rect2
	var half_w: float = THRESHOLD_WIDTH * 0.5
	match s:
		RoomExit.Side.LEFT:
			tunnel_rect = Rect2(-PASSAGE_DEPTH, -half_w, PASSAGE_DEPTH, THRESHOLD_WIDTH)
		RoomExit.Side.RIGHT:
			tunnel_rect = Rect2(0.0, -half_w, PASSAGE_DEPTH, THRESHOLD_WIDTH)
		RoomExit.Side.TOP:
			tunnel_rect = Rect2(-half_w, -PASSAGE_DEPTH, THRESHOLD_WIDTH, PASSAGE_DEPTH)
		RoomExit.Side.BOTTOM:
			tunnel_rect = Rect2(-half_w, 0.0, THRESHOLD_WIDTH, PASSAGE_DEPTH)

	# 1. Dark recessed tunnel void.
	var tunnel_bg: Color = Color("050c12")
	if is_glitter:
		tunnel_bg = Color("071620")
	elif is_cracked:
		tunnel_bg = Color("0a0514")
	draw_rect(tunnel_rect, tunnel_bg)

	# Subtle interior tunnel perspective lines.
	var inner_color := Color(tunnel_bg.lightened(0.12), 0.7)
	match s:
		RoomExit.Side.LEFT, RoomExit.Side.RIGHT:
			draw_line(Vector2(tunnel_rect.position.x, tunnel_rect.position.y),
					  Vector2(tunnel_rect.end.x, tunnel_rect.position.y), inner_color, 1.5)
			draw_line(Vector2(tunnel_rect.position.x, tunnel_rect.end.y),
					  Vector2(tunnel_rect.end.x, tunnel_rect.end.y), inner_color, 1.5)
		RoomExit.Side.TOP, RoomExit.Side.BOTTOM:
			draw_line(Vector2(tunnel_rect.position.x, tunnel_rect.position.y),
					  Vector2(tunnel_rect.position.x, tunnel_rect.end.y), inner_color, 1.5)
			draw_line(Vector2(tunnel_rect.end.x, tunnel_rect.position.y),
					  Vector2(tunnel_rect.end.x, tunnel_rect.end.y), inner_color, 1.5)

	# 2. Threshold floor lip continuing slightly into room.
	var threshold_tint: Color = Color(0.1, 0.25, 0.35, 0.20)
	if is_glitter:
		threshold_tint = Color(0.1, 0.45, 0.48, 0.25)
	elif is_cracked:
		threshold_tint = Color(0.25, 0.12, 0.35, 0.25)
	draw_rect(threshold, threshold_tint)

	# 3. Flanking stone/ice pillars and archway.
	_draw_archway(s, half_w, is_glitter, is_cracked)

	# 4. Barricade or open passage.
	if open_ratio < 1.0:
		_draw_barricade(s, tunnel_rect, half_w, is_cracked)

	# 5. Dwell progress indicator (when standing in threshold).
	if not locked and progress() > 0.0:
		_draw_progress(s, half_w)

func _draw_archway(s: int, half_w: float, is_glitter: bool, is_cracked: bool) -> void:
	var pillar_color := Color("244050")
	var highlight_color := Color("4a7890")

	if is_glitter:
		pillar_color = Color("1e4a58")
		highlight_color = Color("7fe0c4")
	elif is_cracked:
		pillar_color = Color("2e1f40")
		highlight_color = Color("8b5cf6")

	var p1: Rect2
	var p2: Rect2
	if is_horizontal():
		p1 = Rect2(-10.0, -half_w - PILLAR_WIDTH, 20.0, PILLAR_WIDTH)
		p2 = Rect2(-10.0, half_w, 20.0, PILLAR_WIDTH)
	else:
		p1 = Rect2(-half_w - PILLAR_WIDTH, -10.0, PILLAR_WIDTH, 20.0)
		p2 = Rect2(half_w, -10.0, PILLAR_WIDTH, 20.0)

	draw_rect(p1, pillar_color)
	draw_rect(p2, pillar_color)
	draw_rect(p1, highlight_color, false, 1.5)
	draw_rect(p2, highlight_color, false, 1.5)

	# Hollow Shelf Environmental Storytelling:
	# LEFT (Glitter Seam): Shimmering ice crystals on pillars & lintel.
	if is_glitter:
		_draw_crystal_cluster(p1.get_center(), Color("8fe6cf"), Color("f1ffff"))
		_draw_crystal_cluster(p2.get_center(), Color("8fe6cf"), Color("f1ffff"))
	# RIGHT (Cracked Gallery): Threatening fracture cracks radiating outward.
	elif is_cracked:
		_draw_fracture_cracks(p1.get_center(), p2.get_center(), s)

func _draw_crystal_cluster(origin: Vector2, color_mid: Color, color_tip: Color) -> void:
	# Small multi-faceted crystals crowning the doorway frame.
	var poly1 := PackedVector2Array([
		origin + Vector2(-6, 4), origin + Vector2(-3, -12),
		origin + Vector2(2, -16), origin + Vector2(5, 4)
	])
	draw_colored_polygon(poly1, color_mid)
	draw_polyline(poly1, color_tip, 1.5, true)
	var poly2 := PackedVector2Array([
		origin + Vector2(2, 6), origin + Vector2(8, -8),
		origin + Vector2(12, 6)
	])
	draw_colored_polygon(poly2, color_mid.darkened(0.2))

func _draw_fracture_cracks(p1_pos: Vector2, p2_pos: Vector2, s: int) -> void:
	var crack_color := Color("c084fc", 0.75)
	var crack_dark := Color("3b1458", 0.9)
	# Jagged cracks cutting from pillars into the floor.
	var offset_dir := Vector2(-25, 15) if s == RoomExit.Side.RIGHT else Vector2(25, 15)
	var crack1 := PackedVector2Array([p1_pos, p1_pos + offset_dir * 0.5, p1_pos + offset_dir + Vector2(0, 10)])
	var crack2 := PackedVector2Array([p2_pos, p2_pos + offset_dir * 0.5, p2_pos + offset_dir + Vector2(0, -10)])
	draw_polyline(crack1, crack_dark, 3.0, true)
	draw_polyline(crack1, crack_color, 1.5, true)
	draw_polyline(crack2, crack_dark, 3.0, true)
	draw_polyline(crack2, crack_color, 1.5, true)

func _draw_barricade(s: int, tunnel_rect: Rect2, half_w: float, is_cracked: bool) -> void:
	var slab_color := Color("3d5a73", 0.92)
	var ice_rim := Color("a0d8e8", 0.9)
	if is_cracked:
		slab_color = Color("402b48", 0.92)
		ice_rim = Color("a882c0", 0.9)

	# As open_ratio increases (combat cleared), the slab slides down/retracts into the threshold.
	var slab_rect: Rect2
	if is_horizontal():
		var total_h: float = THRESHOLD_WIDTH * (1.0 - open_ratio)
		slab_rect = Rect2(-12.0, -half_w + (THRESHOLD_WIDTH - total_h), 24.0, total_h)
	else:
		var total_w: float = THRESHOLD_WIDTH * (1.0 - open_ratio)
		slab_rect = Rect2(-total_w * 0.5, -12.0, total_w, 24.0)

	if slab_rect.size.x > 4 and slab_rect.size.y > 4:
		draw_rect(slab_rect, slab_color)
		draw_rect(slab_rect, ice_rim, false, 2.0)
		# Cross-brace reinforcing the barricade.
		var c: Vector2 = slab_rect.get_center()
		draw_line(Vector2(slab_rect.position.x, c.y), Vector2(slab_rect.end.x, c.y), ice_rim, 1.5)
		draw_line(Vector2(c.x, slab_rect.position.y), Vector2(c.x, slab_rect.end.y), ice_rim, 1.5)

func _draw_progress(s: int, half_w: float) -> void:
	var p: float = progress()
	var bar_color := Color("e8fff8")
	var bar_thickness: float = 5.0
	match s:
		RoomExit.Side.LEFT:
			var start_x: float = threshold.end.x - bar_thickness
			var bar := Rect2(start_x, -half_w, bar_thickness, THRESHOLD_WIDTH * p)
			draw_rect(bar, bar_color)
		RoomExit.Side.RIGHT:
			var bar := Rect2(threshold.position.x, -half_w, bar_thickness, THRESHOLD_WIDTH * p)
			draw_rect(bar, bar_color)
		RoomExit.Side.TOP:
			var start_y: float = threshold.end.y - bar_thickness
			var bar := Rect2(-half_w, start_y, THRESHOLD_WIDTH * p, bar_thickness)
			draw_rect(bar, bar_color)
		RoomExit.Side.BOTTOM:
			var bar := Rect2(-half_w, threshold.position.y, THRESHOLD_WIDTH * p, bar_thickness)
			draw_rect(bar, bar_color)

func _draw_captions(s: int, accent: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var caption_offset: Vector2
	var width: float = 240.0
	var align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER
	match s:
		RoomExit.Side.LEFT:
			caption_offset = Vector2(THRESHOLD_DEPTH + 18.0, -22.0)
			align = HORIZONTAL_ALIGNMENT_LEFT
		RoomExit.Side.RIGHT:
			caption_offset = Vector2(-THRESHOLD_DEPTH - width - 18.0, -22.0)
			align = HORIZONTAL_ALIGNMENT_RIGHT
		RoomExit.Side.TOP:
			caption_offset = Vector2(-CAPTION_WIDTH * 0.5, THRESHOLD_DEPTH + 18.0)
			width = CAPTION_WIDTH
			align = HORIZONTAL_ALIGNMENT_CENTER
		RoomExit.Side.BOTTOM:
			caption_offset = Vector2(-CAPTION_WIDTH * 0.5, -THRESHOLD_DEPTH - 54.0)
			width = CAPTION_WIDTH
			align = HORIZONTAL_ALIGNMENT_CENTER

	var cx: float = caption_offset.x
	var cy: float = caption_offset.y

	# Route name.
	draw_string(font, Vector2(cx, cy), label(), align, width, 15, Color("dff3f7"))

	# Subtitle / Lock status.
	var subtitle: String = lock_reason if locked else hint()
	if not subtitle.is_empty():
		draw_string(font, Vector2(cx, cy + 18), subtitle, align, width, 12, Color(accent, 0.95))

	# Co-op waiting feedback.
	if not locked and missing() > 0:
		var wait_text: String = _waiting_text()
		if not wait_text.is_empty():
			draw_string(font, Vector2(cx, cy + 36), wait_text, align, width, 12, Color("bcd6df"))

func _waiting_text() -> String:
	if party == null:
		return ""
	var absent := PackedStringArray()
	for player: PenguinPlayer in party.members(true):
		var local: Vector2 = player.global_position - global_position
		if not threshold.has_point(local):
			absent.append("P%d" % player.identity.player_id)
	if absent.is_empty():
		return ""
	if absent.size() == 1:
		return "WAITING FOR %s" % absent[0]
	return "WAITING FOR %d PENGUINS" % absent.size()
