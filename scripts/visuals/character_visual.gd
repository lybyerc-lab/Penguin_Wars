class_name CharacterVisual
extends Node2D
## Cosmetic-only animation and team colors, independent from movement/health rules.
@export var enemy: bool = false
var _time: float = 0.0
var _body: Sprite2D
var _scarf: Sprite2D
var _actor: CharacterBody2D

func _ready() -> void:
	_actor = get_parent() as CharacterBody2D
	_body = Sprite2D.new()
	_body.texture = preload("res://assets/characters/seal_raider.svg") if enemy else preload("res://assets/characters/penguin.svg")
	_body.scale = Vector2.ONE * (0.55 if enemy else 0.54)
	_body.position.y = -9
	add_child(_body)
	if not enemy:
		_scarf = Sprite2D.new()
		_scarf.texture = preload("res://assets/characters/scarf.svg")
		_scarf.modulate = (_actor as PenguinPlayer).identity.tint
		_body.add_child(_scarf)

func _process(delta: float) -> void:
	_time += delta
	var moving: bool = _actor.velocity.length_squared() > 20
	var alive: bool = (_actor.get_node("Health") as Health).is_alive()
	var bob: float = sin(_time * 13.0) * 2.2 if moving and alive else sin(_time * 2.5) * 0.7
	_body.position.y = -9 + bob
	_body.rotation = sin(_time * 13.0) * 0.06 if moving and alive else 0.0
	_body.modulate = Color.WHITE if alive else Color("758794")
	if not alive:
		_body.rotation = PI * 0.5
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0, 13), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 24, Color(0.02, 0.12, 0.2, 0.24))
	draw_set_transform(Vector2.ZERO)
