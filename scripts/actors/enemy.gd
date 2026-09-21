class_name ArenaEnemy
extends CharacterBody2D

signal defeated(enemy: ArenaEnemy, event: DamageEvent)

@export var speed: float = 72.0
@export var contact_damage: float = 8.0
var party: PartyRoster
var _attack_remaining: float = 0.0
var _knockback := Vector2.ZERO
@onready var health: Health = $Health

func _ready() -> void:
	add_to_group("enemies")
	health.died.connect(_on_died)
	health.damaged.connect(func(event: DamageEvent) -> void: _knockback += event.impulse)

func _physics_process(delta: float) -> void:
	if not health.is_alive() or party == null:
		return
	_attack_remaining = maxf(0.0, _attack_remaining - delta)
	var target: PenguinPlayer = party.nearest_alive(global_position)
	if target == null:
		velocity = Vector2.ZERO
		return
	velocity = global_position.direction_to(target.global_position) * speed + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 1000.0 * delta)
	move_and_slide()
	if global_position.distance_to(target.global_position) < 34.0 and _attack_remaining <= 0.0:
		target.health.take_damage(DamageEvent.new(contact_damage))
		_attack_remaining = 0.8

func _on_died(event: DamageEvent) -> void:
	defeated.emit(self, event)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2(0, 7), 16, Color(0, 0, 0, 0.18))
	draw_circle(Vector2.ZERO, 15, Color("eb7985"))
	draw_circle(Vector2(-5, -3), 3, Color("2a1e38"))
	draw_circle(Vector2(5, -3), 3, Color("2a1e38"))
