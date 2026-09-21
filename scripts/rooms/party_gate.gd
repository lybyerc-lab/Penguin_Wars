class_name PartyGate
extends Node2D
## A way out of a room. Travel is positional and shared: every living penguin
## stands on the pad together, so branching adds no new input binding and one
## player cannot drag the party through a door alone.

signal travelled(gate: PartyGate)

const RADIUS: float = 64.0
## How long the whole party must hold the pad. Long enough to be deliberate,
## short enough not to feel like a chore between rooms.
const DWELL: float = 1.0
## Wider than the pad, so a long route name is never truncated.
const CAPTION_WIDTH: float = 360.0

var exit: RoomExit
var party: PartyRoster
var locked: bool = true
var lock_reason: String = "Clear the room first"
var dwell: float = 0.0
var spent: bool = false

func _ready() -> void:
	z_index = -2

func label() -> String:
	return exit.label if exit != null else "Onward"

func hint() -> String:
	return exit.hint if exit != null else ""

func standing() -> int:
	if party == null:
		return 0
	var count: int = 0
	for player: PenguinPlayer in party.members(true):
		if player.global_position.distance_to(global_position) <= RADIUS:
			count += 1
	return count

## Living penguins still needed on the pad.
func missing() -> int:
	if party == null:
		return 0
	return maxi(0, party.members(true).size() - standing())

func progress() -> float:
	return clampf(dwell / DWELL, 0.0, 1.0)

func _physics_process(delta: float) -> void:
	if spent or party == null:
		return
	var living: int = party.members(true).size()
	if locked or living == 0 or standing() < living:
		# Decay quickly so stepping off clearly cancels the departure.
		dwell = maxf(0.0, dwell - delta * 2.0)
	else:
		dwell += delta
		if dwell >= DWELL:
			spent = true
			travelled.emit(self)
	queue_redraw()

func _draw() -> void:
	var accent: Color = Color("5a6b7d") if locked else Color("7fe0c4")
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
	draw_circle(Vector2.ZERO, RADIUS, Color(accent, 0.14))
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 48, Color(accent, 0.8), 3)
	if not locked:
		draw_arc(Vector2.ZERO, RADIUS - 10, -PI * 0.5, -PI * 0.5 + TAU * progress(), 48, Color("e8fff8"), 5)
	draw_set_transform(Vector2.ZERO)
	# Captions are wider than the pad so a route name is never clipped.
	var font: Font = ThemeDB.fallback_font
	var origin: float = -CAPTION_WIDTH * 0.5
	draw_string(font, Vector2(origin, -RADIUS * 0.5 - 24), label(), HORIZONTAL_ALIGNMENT_CENTER, CAPTION_WIDTH, 15, Color("dff3f7"))
	var subtitle: String = lock_reason if locked else hint()
	if not subtitle.is_empty():
		draw_string(font, Vector2(origin, -RADIUS * 0.5 - 8), subtitle, HORIZONTAL_ALIGNMENT_CENTER, CAPTION_WIDTH, 12, Color(accent, 0.95))
	if not locked and missing() > 0:
		draw_string(font, Vector2(origin, RADIUS * 0.5 + 18), "Waiting for %d more" % missing(), HORIZONTAL_ALIGNMENT_CENTER, CAPTION_WIDTH, 12, Color("bcd6df"))
