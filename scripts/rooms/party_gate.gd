class_name PartyGate
extends Node2D
## A way out of a room. Travel is positional and shared: every living penguin
## enters the doorway together, so branching adds no new input binding and one
## player cannot drag the party through a door alone.
##
## Presentation: chunky, physical cave openings carved into the room walls,
## inspired by classic top-down adventure games.

signal travelled(gate: PartyGate)

## Doorway threshold dimensions: 90px deep into room × 130px wide/tall along wall.
const THRESHOLD_DEPTH: float = 90.0
const THRESHOLD_WIDTH: float = 130.0
## Grand expedition cave mouth in town.
const TOWN_MOUTH_WIDTH: float = 210.0
## Deliberate dwell time for passing through a doorway.
const DWELL: float = 0.4
## Visual depth of the passage "tunnel" drawn beyond the room edge.
const PASSAGE_DEPTH: float = 55.0
## Width reserved for caption text.
const CAPTION_WIDTH: float = 240.0
## Pillar width flanking the passage opening.
const PILLAR_WIDTH: float = 22.0

var exit: RoomExit
var party: PartyRoster
var palette: int = 0
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

func is_town_mouth() -> bool:
	return exit != null and exit.target_id == &"hollow_shelf"

func gate_width() -> float:
	return TOWN_MOUTH_WIDTH if is_town_mouth() else THRESHOLD_WIDTH

## Position this gate flush against the specified room boundary wall.
## Threshold rectangle is oriented to extend THRESHOLD_DEPTH into the room
## and gate_width() along the wall.
func place_at_wall(bounds: Rect2) -> void:
	if exit == null:
		return
	position = RoomExit.wall_position(bounds, exit.side)
	var w: float = gate_width()
	match exit.side:
		RoomExit.Side.LEFT:
			# Wall at left; threshold extends into the room to the right (+x).
			threshold = Rect2(-15.0, -w * 0.5, THRESHOLD_DEPTH + 15.0, w)
		RoomExit.Side.RIGHT:
			# Wall at right; threshold extends into the room to the left (-x).
			threshold = Rect2(-THRESHOLD_DEPTH, -w * 0.5, THRESHOLD_DEPTH + 15.0, w)
		RoomExit.Side.TOP:
			# Wall at top; threshold extends into the room downwards (+y).
			threshold = Rect2(-w * 0.5, -15.0, w, THRESHOLD_DEPTH + 15.0)
		RoomExit.Side.BOTTOM:
			# Wall at bottom; threshold extends into the room upwards (-y).
			threshold = Rect2(-w * 0.5, -THRESHOLD_DEPTH, w, THRESHOLD_DEPTH + 15.0)

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
	_draw_passage(s)
	_draw_captions(s)

func _get_palette_theme() -> Dictionary:
	match palette:
		1:  # CAVE
			return {
				"mouth": Color("221834"), "mid": Color("140c20"), "deep": Color("07040d"),
				"rock": Color("2e1f40"), "rock_light": Color("4a3560"), "bevel": Color("181024"),
				"highlight": Color("8b5cf6"), "frost": Color("c3b0e9"),
			}
		2:  # DEEP
			return {
				"mouth": Color("12272e"), "mid": Color("08171d"), "deep": Color("030b0e"),
				"rock": Color("1a3840"), "rock_light": Color("2d5560"), "bevel": Color("0c1a20"),
				"highlight": Color("3fae9d"), "frost": Color("8fe6cf"),
			}
		_:  # 0: ICE
			return {
				"mouth": Color("142e3d"), "mid": Color("0c1c26"), "deep": Color("050e14"),
				"rock": Color("244050"), "rock_light": Color("3b6074"), "bevel": Color("14222c"),
				"highlight": Color("4a7890"), "frost": Color("a0d8e8"),
			}

func _draw_passage(s: int) -> void:
	var target: StringName = exit.target_id if exit != null else &""
	var is_glitter: bool = target == &"glitter_seam"
	var is_cracked: bool = target == &"cracked_gallery"
	var is_town: bool = is_town_mouth()
	var is_boss: bool = (exit != null and exit.leads_outside() and palette == 2)

	var theme: Dictionary = _get_palette_theme()
	if is_glitter:
		theme["mouth"] = Color("0d2836")
		theme["mid"] = Color("071a24")
		theme["deep"] = Color("030d14")
		theme["highlight"] = Color("7fe0c4")
		theme["frost"] = Color("e8fff8")
	elif is_cracked:
		theme["mouth"] = Color("1e122c")
		theme["mid"] = Color("12091c")
		theme["deep"] = Color("08040e")
		theme["rock"] = Color("281838")
		theme["highlight"] = Color("a855f7")

	var w: float = gate_width()
	var half_w: float = w * 0.5

	# 1. Layered Nested Recessed Tunnel Interior (No flat black!).
	_draw_recessed_tunnel(s, half_w, theme, is_town)

	# 2. Chunky Carved Stone/Ice Pillars & Arch Frame.
	if is_town:
		_draw_town_expedition_mouth(half_w, theme)
	elif is_glitter:
		_draw_glitter_arch(s, half_w, theme)
	elif is_cracked:
		_draw_cracked_arch(s, half_w, theme)
	else:
		_draw_standard_arch(s, half_w, theme)

	# 3. Barricade or Open Passage.
	if open_ratio < 1.0:
		_draw_chunky_barricade(s, half_w, theme, is_cracked, is_boss)

	# 4. Dwell Progress Indicator along inner threshold lip.
	if not locked and progress() > 0.0:
		_draw_progress(s, half_w)

## Draws 3 nested, arched receding tunnel layers into the wall depth.
func _draw_recessed_tunnel(s: int, half_w: float, theme: Dictionary, is_town: bool) -> void:
	var mouth_color: Color = theme["mouth"]
	var mid_color: Color = theme["mid"]
	var deep_color: Color = theme["deep"]

	# Layer 1: Outer tunnel cavity
	var rect_outer: Rect2
	var rect_mid: Rect2
	var rect_deep: Rect2

	match s:
		RoomExit.Side.LEFT:
			rect_outer = Rect2(-PASSAGE_DEPTH, -half_w, PASSAGE_DEPTH + 10.0, half_w * 2.0)
			rect_mid = Rect2(-PASSAGE_DEPTH, -half_w + 12.0, PASSAGE_DEPTH - 10.0, half_w * 2.0 - 24.0)
			rect_deep = Rect2(-PASSAGE_DEPTH, -half_w + 24.0, PASSAGE_DEPTH - 22.0, half_w * 2.0 - 48.0)
		RoomExit.Side.RIGHT:
			rect_outer = Rect2(-10.0, -half_w, PASSAGE_DEPTH + 10.0, half_w * 2.0)
			rect_mid = Rect2(10.0, -half_w + 12.0, PASSAGE_DEPTH - 10.0, half_w * 2.0 - 24.0)
			rect_deep = Rect2(22.0, -half_w + 24.0, PASSAGE_DEPTH - 22.0, half_w * 2.0 - 48.0)
		RoomExit.Side.TOP:
			rect_outer = Rect2(-half_w, -PASSAGE_DEPTH, half_w * 2.0, PASSAGE_DEPTH + 10.0)
			rect_mid = Rect2(-half_w + 14.0, -PASSAGE_DEPTH, half_w * 2.0 - 28.0, PASSAGE_DEPTH - 10.0)
			rect_deep = Rect2(-half_w + 28.0, -PASSAGE_DEPTH, half_w * 2.0 - 56.0, PASSAGE_DEPTH - 22.0)
		RoomExit.Side.BOTTOM:
			var depth: float = PASSAGE_DEPTH + (20.0 if is_town else 0.0)
			rect_outer = Rect2(-half_w, -10.0, half_w * 2.0, depth + 10.0)
			rect_mid = Rect2(-half_w + 14.0, 10.0, half_w * 2.0 - 28.0, depth - 10.0)
			rect_deep = Rect2(-half_w + 28.0, 22.0, half_w * 2.0 - 56.0, depth - 22.0)

	draw_rect(rect_outer, mouth_color)
	draw_rect(rect_mid, mid_color)
	draw_rect(rect_deep, deep_color)

	# Faint perspective depth lines in tunnel ceiling/corners.
	var line_color := Color(deep_color.lightened(0.18), 0.6)
	match s:
		RoomExit.Side.LEFT:
			draw_line(Vector2(0, -half_w), Vector2(-PASSAGE_DEPTH, -half_w + 24.0), line_color, 1.5)
			draw_line(Vector2(0, half_w), Vector2(-PASSAGE_DEPTH, half_w - 24.0), line_color, 1.5)
		RoomExit.Side.RIGHT:
			draw_line(Vector2(0, -half_w), Vector2(PASSAGE_DEPTH, -half_w + 24.0), line_color, 1.5)
			draw_line(Vector2(0, half_w), Vector2(PASSAGE_DEPTH, half_w - 24.0), line_color, 1.5)
		RoomExit.Side.TOP:
			draw_line(Vector2(-half_w, 0), Vector2(-half_w + 28.0, -PASSAGE_DEPTH), line_color, 1.5)
			draw_line(Vector2(half_w, 0), Vector2(half_w - 28.0, -PASSAGE_DEPTH), line_color, 1.5)
		RoomExit.Side.BOTTOM:
			draw_line(Vector2(-half_w, 0), Vector2(-half_w + 28.0, PASSAGE_DEPTH), line_color, 1.5)
			draw_line(Vector2(half_w, 0), Vector2(half_w - 28.0, PASSAGE_DEPTH), line_color, 1.5)

## Chunky carved rock/ice arch for standard cave doorways.
func _draw_standard_arch(s: int, half_w: float, theme: Dictionary) -> void:
	var rock: Color = theme["rock"]
	var rock_light: Color = theme["rock_light"]
	var bevel: Color = theme["bevel"]
	var hl: Color = theme["highlight"]

	var pw: float = PILLAR_WIDTH
	var p1: Rect2
	var p2: Rect2

	if is_horizontal():
		p1 = Rect2(-14.0, -half_w - pw, 28.0, pw)
		p2 = Rect2(-14.0, half_w, 28.0, pw)
	else:
		p1 = Rect2(-half_w - pw, -14.0, pw, 28.0)
		p2 = Rect2(half_w, -14.0, pw, 28.0)

	# Pillar bases with chunky stone block joints
	_draw_chunky_pillar_blocks(p1, rock, rock_light, bevel, hl, is_horizontal())
	_draw_chunky_pillar_blocks(p2, rock, rock_light, bevel, hl, is_horizontal())

## Glitter Seam: Faceted crystalline arch crowned with luminous ice crystals.
func _draw_glitter_arch(s: int, half_w: float, theme: Dictionary) -> void:
	var rock: Color = theme["rock"]
	var rock_light: Color = theme["rock_light"]
	var bevel: Color = theme["bevel"]
	var hl: Color = theme["highlight"]

	var pw: float = PILLAR_WIDTH
	var p1 := Rect2(-14.0, -half_w - pw, 28.0, pw)
	var p2 := Rect2(-14.0, half_w, 28.0, pw)

	_draw_chunky_pillar_blocks(p1, rock, rock_light, bevel, hl, true)
	_draw_chunky_pillar_blocks(p2, rock, rock_light, bevel, hl, true)

	# Luminous crystal spires flanking the arch
	_draw_faceted_crystal(p1.get_center() + Vector2(0, -4), 16.0, Color("8fe6cf"), Color("f1ffff"))
	_draw_faceted_crystal(p1.get_center() + Vector2(10, 6), 10.0, Color("48a8b8"), Color("e8fff8"))
	_draw_faceted_crystal(p2.get_center() + Vector2(0, 4), 16.0, Color("8fe6cf"), Color("f1ffff"))
	_draw_faceted_crystal(p2.get_center() + Vector2(10, -6), 10.0, Color("48a8b8"), Color("e8fff8"))

	# Clean crystalline lintel bevel
	draw_line(Vector2(0, -half_w), Vector2(0, half_w), Color("7fe0c4", 0.4), 2.0)

## Cracked Gallery: Broken asymmetrical obsidian arch with jagged cracks.
func _draw_cracked_arch(s: int, half_w: float, theme: Dictionary) -> void:
	var rock: Color = theme["rock"]
	var rock_light: Color = theme["rock_light"]
	var bevel: Color = theme["bevel"]
	var hl: Color = theme["highlight"]

	var pw: float = PILLAR_WIDTH
	# Asymmetrical: Top pillar broken with dislodged rock slab
	var p1 := Rect2(-16.0, -half_w - pw - 6.0, 32.0, pw + 6.0)
	var p2 := Rect2(-14.0, half_w, 28.0, pw - 4.0)

	_draw_chunky_pillar_blocks(p1, rock, rock_light, bevel, hl, true)
	_draw_chunky_pillar_blocks(p2, rock, rock_light, bevel, hl, true)

	# Dislodged jagged stone slab leaning into opening
	var slab := PackedVector2Array([
		Vector2(-12, -half_w - 4), Vector2(6, -half_w + 8),
		Vector2(2, -half_w + 18), Vector2(-16, -half_w + 6)
	])
	draw_colored_polygon(slab, rock_light)
	draw_polyline(slab, hl, 1.5, true)

	# Deep purple fracture cracks radiating into the room
	var c1 := PackedVector2Array([
		p1.get_center(), p1.get_center() + Vector2(-28, -16),
		p1.get_center() + Vector2(-55, -8), p1.get_center() + Vector2(-75, -20)
	])
	var c2 := PackedVector2Array([
		p2.get_center(), p2.get_center() + Vector2(-26, 18),
		p2.get_center() + Vector2(-60, 12), p2.get_center() + Vector2(-80, 26)
	])
	draw_polyline(c1, Color("2a083d"), 3.5, true)
	draw_polyline(c1, Color("c084fc", 0.8), 1.5, true)
	draw_polyline(c2, Color("2a083d"), 3.5, true)
	draw_polyline(c2, Color("c084fc", 0.8), 1.5, true)

## Kelphollow Town: Broad natural expedition mouth with weathered timbers.
func _draw_town_expedition_mouth(half_w: float, theme: Dictionary) -> void:
	var rock: Color = Color("244050")
	var rock_light: Color = Color("3b6074")
	var timber: Color = Color("422f20")
	var timber_hl: Color = Color("684b34")
	var iron: Color = Color("2e3842")
	var snow: Color = Color("dff2f8")

	# Heavy natural rock boulders framing the wide mouth
	var boulder_left := Rect2(-half_w - 28.0, -18.0, 36.0, 36.0)
	var boulder_right := Rect2(half_w - 8.0, -18.0, 36.0, 36.0)
	draw_rect(boulder_left, rock)
	draw_rect(boulder_right, rock)
	draw_rect(boulder_left, rock_light, false, 2.0)
	draw_rect(boulder_right, rock_light, false, 2.0)

	# Weathered wooden support guide posts flanking the entrance
	var post_w: float = 14.0
	var post_h: float = 46.0
	var post_l := Rect2(-half_w + 4.0, -22.0, post_w, post_h)
	var post_r := Rect2(half_w - 18.0, -22.0, post_w, post_h)
	draw_rect(post_l, timber)
	draw_rect(post_r, timber)
	draw_rect(Rect2(post_l.position, Vector2(2, post_h)), timber_hl)
	draw_rect(Rect2(post_r.position, Vector2(2, post_h)), timber_hl)

	# Iron straps & bolts on timber posts
	draw_rect(Rect2(post_l.position.x - 1, post_l.position.y + 10, post_w + 2, 4), iron)
	draw_rect(Rect2(post_l.position.x - 1, post_l.position.y + 30, post_w + 2, 4), iron)
	draw_rect(Rect2(post_r.position.x - 1, post_r.position.y + 10, post_w + 2, 4), iron)
	draw_rect(Rect2(post_r.position.x - 1, post_r.position.y + 30, post_w + 2, 4), iron)

	# Snow crust settled on boulder tops
	draw_circle(boulder_left.get_center() + Vector2(0, -14), 14.0, snow)
	draw_circle(boulder_right.get_center() + Vector2(0, -14), 14.0, snow)

## Draws chunky stone blocks with bevels and mortar joints.
func _draw_chunky_pillar_blocks(r: Rect2, rock: Color, rock_light: Color, bevel: Color, hl: Color, horizontal: bool) -> void:
	draw_rect(r, rock)
	draw_rect(r, bevel, false, 2.0)

	# Inner carved bevel
	if horizontal:
		var mid_y: float = r.position.y + r.size.y * 0.5
		draw_line(Vector2(r.position.x, mid_y), Vector2(r.end.x, mid_y), bevel, 2.0)
		draw_line(Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y), rock_light, 1.5)
		draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), hl, 1.5)
	else:
		var mid_x: float = r.position.x + r.size.x * 0.5
		draw_line(Vector2(mid_x, r.position.y), Vector2(mid_x, r.end.y), bevel, 2.0)
		draw_line(Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.end.y), rock_light, 1.5)
		draw_line(Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y), hl, 1.5)

## Faceted crystalline gem spire.
func _draw_faceted_crystal(origin: Vector2, size: float, mid_color: Color, tip_color: Color) -> void:
	var h: float = size
	var w: float = size * 0.4
	var poly := PackedVector2Array([
		origin + Vector2(-w, h * 0.5), origin + Vector2(0, -h),
		origin + Vector2(w, h * 0.5)
	])
	draw_colored_polygon(poly, mid_color)
	draw_polyline(poly, tip_color, 1.5, true)

## Massive physical glacial rock/ice monolith barricade.
func _draw_chunky_barricade(s: int, half_w: float, theme: Dictionary, is_cracked: bool, is_boss: bool) -> void:
	var slab_base: Color = Color("2e4a5e") if not is_cracked else Color("321e3c")
	var ice_rime: Color = Color("92d4ea") if not is_cracked else Color("9a78b5")
	var frost_cap: Color = Color("e0f6fc")

	# Retracts cleanly into the threshold floor as open_ratio advances.
	var open_inv: float = 1.0 - open_ratio
	var bar_w: float = half_w * 2.0 * open_inv
	if bar_w < 6.0:
		return

	var slab_rect: Rect2
	if is_horizontal():
		var h: float = half_w * 2.0 * open_inv
		slab_rect = Rect2(-14.0, -half_w + (half_w * 2.0 - h), 28.0, h)
	else:
		slab_rect = Rect2(-bar_w * 0.5, -14.0, bar_w, 28.0)

	# Main monolithic ice stone slab
	draw_rect(slab_rect, slab_base)
	draw_rect(slab_rect, ice_rime, false, 2.0)

	# Heavy cross-braces and fracture joints
	var c: Vector2 = slab_rect.get_center()
	draw_line(Vector2(slab_rect.position.x, c.y), Vector2(slab_rect.end.x, c.y), ice_rime, 2.0)
	draw_line(Vector2(c.x, slab_rect.position.y), Vector2(c.x, slab_rect.end.y), ice_rime, 2.0)

	# Frost crust along upper seam
	var cap_line := Vector2(slab_rect.position.x, slab_rect.position.y)
	draw_line(cap_line, cap_line + Vector2(slab_rect.size.x, 0), frost_cap, 2.5)

	# Extra boss glacial spikes if Frostbreaker exit
	if is_boss and open_ratio < 0.2:
		var spike1 := PackedVector2Array([Vector2(-20, -14), Vector2(-12, -28), Vector2(-4, -14)])
		var spike2 := PackedVector2Array([Vector2(4, -14), Vector2(12, -32), Vector2(20, -14)])
		draw_colored_polygon(spike1, ice_rime)
		draw_colored_polygon(spike2, ice_rime)

## Dwell progress bar along inner threshold lip.
func _draw_progress(s: int, half_w: float) -> void:
	var p: float = progress()
	var bar_color := Color("e8fff8")
	var bar_thickness: float = 4.5
	var w: float = gate_width()

	match s:
		RoomExit.Side.LEFT:
			var start_x: float = threshold.end.x - bar_thickness
			draw_rect(Rect2(start_x, -half_w, bar_thickness, w * p), bar_color)
		RoomExit.Side.RIGHT:
			draw_rect(Rect2(threshold.position.x, -half_w, bar_thickness, w * p), bar_color)
		RoomExit.Side.TOP:
			var start_y: float = threshold.end.y - bar_thickness
			draw_rect(Rect2(-half_w, start_y, w * p, bar_thickness), bar_color)
		RoomExit.Side.BOTTOM:
			draw_rect(Rect2(-half_w, threshold.position.y, w * p, bar_thickness), bar_color)

## Route captions & subtle co-op waiting text.
func _draw_captions(s: int) -> void:
	var font: Font = ThemeDB.fallback_font
	var caption_offset: Vector2
	var width: float = CAPTION_WIDTH
	var align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER

	match s:
		RoomExit.Side.LEFT:
			caption_offset = Vector2(THRESHOLD_DEPTH + 18.0, -22.0)
			align = HORIZONTAL_ALIGNMENT_LEFT
		RoomExit.Side.RIGHT:
			caption_offset = Vector2(-THRESHOLD_DEPTH - width - 18.0, -22.0)
			align = HORIZONTAL_ALIGNMENT_RIGHT
		RoomExit.Side.TOP:
			caption_offset = Vector2(-width * 0.5, THRESHOLD_DEPTH + 18.0)
			align = HORIZONTAL_ALIGNMENT_CENTER
		RoomExit.Side.BOTTOM:
			caption_offset = Vector2(-width * 0.5, -THRESHOLD_DEPTH - 52.0)
			align = HORIZONTAL_ALIGNMENT_CENTER

	var cx: float = caption_offset.x
	var cy: float = caption_offset.y

	# 1. Route Name: Bold uppercase, prominent hierarchy
	var title_text: String = label().to_upper()
	draw_string(font, Vector2(cx, cy), title_text, align, width, 14, Color("e2f1f5"))

	# 2. Subtitle / Hint: Softer descriptive hierarchy
	var subtitle: String = lock_reason if locked else hint()
	if not subtitle.is_empty():
		var sub_color := Color("8ea8b8")
		if not locked:
			if exit != null and exit.target_id == &"glitter_seam":
				sub_color = Color("7ec4b8")
			elif exit != null and exit.target_id == &"cracked_gallery":
				sub_color = Color("a088c0")
		draw_string(font, Vector2(cx, cy + 16), subtitle, align, width, 11, sub_color)

	# 3. Co-op waiting feedback: Quiet, unobtrusive status cue
	if not locked and missing() > 0:
		var wait_text: String = _waiting_text()
		if not wait_text.is_empty():
			draw_string(font, Vector2(cx, cy + 32), wait_text, align, width, 10, Color("6c8896"))

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
