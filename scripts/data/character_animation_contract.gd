class_name CharacterAnimationContract
extends RefCounted
## Centralized export and runtime presentation contract for Penguin Wars production character animations.
## Single source of truth for canvas size, ground anchor, source FPS, runtime scale/offset,
## canonical animation states, looping behavior, layer names, and sequential file conventions.

## Current Export Profile Specification
const CANVAS_SIZE: Vector2i = Vector2i(256, 256)
const CANVAS_WIDTH: int = 256
const CANVAS_HEIGHT: int = 256

## Character ground contact line within the 256x256 canvas (x=128 horizontal center, y=216 ground contact)
const GROUND_ANCHOR: Vector2i = Vector2i(128, 216)

## Source framerate for rendered production animation frames
const SOURCE_FPS: float = 24.0

## Default runtime scale applied to the 256x256 sprite
const RUNTIME_SCALE: Vector2 = Vector2(0.25, 0.25)

## Visual offset in local canvas coordinates to align GROUND_ANCHOR with actor origin (0, 0).
## Canvas center is at (128, 128). Ground contact is at (128, 216).
## Shift required: -(216 - 128) = -88 on Y.
const RUNTIME_OFFSET: Vector2 = Vector2(0.0, -88.0)

## Canonical animation states
const CANONICAL_STATES: Array[String] = [
	"idle",
	"move",
	"dash",
	"hit",
	"downed",
	"revive",
]

## Loop configuration per canonical state
const STATE_LOOP_CONFIG: Dictionary = {
	"idle": true,
	"move": true,
	"dash": false,
	"hit": false,
	"downed": false,
	"revive": false,
}

## Two-layer presentation contract
const LAYER_BASE: String = "base"
const LAYER_SCARF: String = "scarf"
const REQUIRED_LAYERS: Array[String] = [LAYER_BASE, LAYER_SCARF]

## File naming convention: penguin_<state>_###.png
const FILE_PREFIX: String = "penguin"

## Canonical asset root paths
const PATH_PRODUCTION_ROOT: String = "res://assets/characters/penguin/production"
const PATH_FIXTURE_ROOT: String = "res://tests/fixtures/character_animation"
const PATH_PRODUCTION_PROFILE: String = "res://resources/characters/penguin_production_profile.tres"
const PATH_PRODUCTION_SPRITE_FRAMES: String = "res://resources/characters/penguin_production_sprite_frames.tres"
const PATH_PRODUCTION_SCARF_FRAMES: String = "res://resources/characters/penguin_production_scarf_sprite_frames.tres"

const PATH_FIXTURE_PROFILE: String = "res://resources/characters/penguin_fixture_profile.tres"
const PATH_FIXTURE_SPRITE_FRAMES: String = "res://resources/characters/penguin_fixture_sprite_frames.tres"
const PATH_FIXTURE_SCARF_FRAMES: String = "res://resources/characters/penguin_fixture_scarf_sprite_frames.tres"

## Formats standard sequential frame filename: penguin_<state>_%03d.png
static func format_frame_filename(state: String, frame_index: int) -> String:
	return "%s_%s_%03d.png" % [FILE_PREFIX, state, frame_index]

## Returns whether a canonical state animation should loop
static func is_state_looping(state: String) -> bool:
	return STATE_LOOP_CONFIG.get(state, false)
