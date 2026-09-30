class_name GroundingEffectPool
extends Node2D
## Fixed presentation-only snow pool shared by every actor in the active scene.

enum Effect { KICK, DASH_PUFF }

const CAPACITY: int = 8
const FPS: float = 24.0
const KICK_TEXTURE: Texture2D = preload("res://assets/effects/grounding_v1/ag_snow_kick_6f.png")
const DASH_PUFF_TEXTURE: Texture2D = preload("res://assets/effects/grounding_v1/ag_snow_puff_dash_8f.png")

var _sprites: Array[Sprite2D] = []
var _elapsed := PackedFloat32Array()
var _frame_counts := PackedInt32Array()

func _ready() -> void:
	z_index = -2
	_ensure_pool()

func _ensure_pool() -> void:
	if not _sprites.is_empty():
		return
	_elapsed.resize(CAPACITY)
	_frame_counts.resize(CAPACITY)
	for index: int in range(CAPACITY):
		var sprite := Sprite2D.new()
		sprite.name = "SnowEffect%d" % index
		sprite.visible = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(sprite)
		_sprites.append(sprite)

func request(effect: Effect, world_position: Vector2, effect_rotation: float, effect_scale: Vector2) -> bool:
	_ensure_pool()
	for index: int in range(CAPACITY):
		var sprite: Sprite2D = _sprites[index]
		if sprite.visible:
			continue
		_configure(index, effect, world_position, effect_rotation, effect_scale)
		return true
	return false

func active_count() -> int:
	var count: int = 0
	for sprite: Sprite2D in _sprites:
		if sprite.visible:
			count += 1
	return count

func capacity() -> int:
	return CAPACITY

func _configure(index: int, effect: Effect, world_position: Vector2, effect_rotation: float, effect_scale: Vector2) -> void:
	var sprite: Sprite2D = _sprites[index]
	if effect == Effect.DASH_PUFF:
		sprite.texture = DASH_PUFF_TEXTURE
		sprite.hframes = 8
		sprite.offset = Vector2(48.0, -24.0)
		_frame_counts[index] = 8
	else:
		sprite.texture = KICK_TEXTURE
		sprite.hframes = 6
		sprite.offset = Vector2(0.0, -16.0)
		_frame_counts[index] = 6
	sprite.frame = 0
	sprite.global_position = world_position
	sprite.rotation = effect_rotation
	sprite.scale = effect_scale
	sprite.visible = true
	_elapsed[index] = 0.0

func _process(delta: float) -> void:
	for index: int in range(_sprites.size()):
		var sprite: Sprite2D = _sprites[index]
		if not sprite.visible:
			continue
		_elapsed[index] += delta
		var next_frame: int = floori(_elapsed[index] * FPS)
		if next_frame >= _frame_counts[index]:
			sprite.visible = false
			continue
		sprite.frame = next_frame
