class_name CharacterPresentationProfile
extends Resource
## Character presentation profile for Penguin Wars.
## Decouples character visuals and animation assets from authoritative gameplay systems.
## Maps canonical animation states (idle, move, dash, hit, downed, revive) to animation
## assets (SpriteFrames) for both base character body and colorized scarf overlay.

enum State {
	IDLE,
	MOVE,
	DASH,
	HIT,
	DOWNED,
	REVIVE,
	WADDLE = 1,
	KO = 4,
}

@export var profile_name: String = "Default"
@export var sprite_frames: SpriteFrames
@export var scarf_sprite_frames: SpriteFrames
@export var base_scale: Vector2 = Vector2.ONE
@export var offset: Vector2 = Vector2.ZERO
@export var flip_h_with_facing: bool = true

## Mapped animation names for the six canonical states
@export var anim_idle: StringName = &"idle"
@export var anim_move: StringName = &"move"
@export var anim_dash: StringName = &"dash"
@export var anim_hit: StringName = &"hit"
@export var anim_downed: StringName = &"downed"
@export var anim_revive: StringName = &"revive"

## Returns the mapped animation name for a given visual state index.
func get_animation_for_state(state: int) -> StringName:
	match state:
		State.DOWNED:
			return anim_downed
		State.REVIVE:
			return anim_revive
		State.HIT:
			return anim_hit
		State.DASH:
			return anim_dash
		State.MOVE:
			return anim_move
		_:
			return anim_idle

## Checks if the base profile has valid animation frames for the given animation name.
func has_animation(anim_name: StringName) -> bool:
	return sprite_frames != null and sprite_frames.has_animation(anim_name)

## Checks if the scarf overlay profile has valid animation frames for the given animation name.
func has_scarf_animation(anim_name: StringName) -> bool:
	return scarf_sprite_frames != null and scarf_sprite_frames.has_animation(anim_name)

## Returns whether the animation configured for the given state is set to loop.
func is_state_looping(state: int) -> bool:
	var anim_name := get_animation_for_state(state)
	if sprite_frames == null or not sprite_frames.has_animation(anim_name):
		return false
	return sprite_frames.get_animation_loop(anim_name)
