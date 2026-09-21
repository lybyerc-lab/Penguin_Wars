class_name ArenaEnemy
extends CharacterBody2D

signal defeated(enemy: ArenaEnemy, event: DamageEvent)

@export var speed: float = 72.0
@export var contact_damage: float = 8.0
@export var projectile_damage: float = 10.0
## How close this enemy must be to land contact damage, and how large a
## target it is. A boss is bigger than a seal raider on both counts.
@export var contact_radius: float = 34.0
@export var hit_radius: float = 21.0
## Scales incoming knockback. Below 1.0 an enemy cannot be pushed around,
## which is what stops heavy weapons stun-locking a large target.
@export var knockback_multiplier: float = 1.0
## Movement clamp. A large body may be inset from the room so it cannot
## overhang the wall, which is why this is not always the room rect.
@export var arena_bounds := Rect2(-540, -260, 1080, 520)
## The room's own rect. Anything that needs the room rather than this actor's
## movement box — projectiles, for one — reads this.
@export var room_bounds := Rect2(-540, -260, 1080, 520)
var party: PartyRoster
var _attack_remaining: float = 0.0
var _knockback := Vector2.ZERO
@onready var health: Health = $Health
@onready var behavior: EnemyBehavior = get_node_or_null("Behavior") as EnemyBehavior

func _ready() -> void:
	add_to_group("enemies")
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)

func _physics_process(delta: float) -> void:
	if not health.is_alive() or party == null:
		return
	_attack_remaining = maxf(0.0, _attack_remaining - delta)
	var target: PenguinPlayer = party.nearest_alive(global_position)
	if target == null:
		velocity = Vector2.ZERO
		if behavior != null:
			behavior.cancel()
		return
	var intended: Vector2 = behavior.movement(self, target, delta) if behavior != null else global_position.direction_to(target.global_position) * speed
	velocity = intended + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 1000.0 * delta)
	move_and_slide()
	global_position = global_position.clamp(arena_bounds.position, arena_bounds.end)
	if global_position.distance_to(target.global_position) < contact_radius and _attack_remaining <= 0.0 and (behavior == null or behavior.contact_enabled()):
		target.health.take_damage(DamageEvent.new(contact_damage))
		_attack_remaining = 0.8

func _on_damaged(event: DamageEvent) -> void:
	_knockback += event.impulse * knockback_multiplier
	if behavior != null:
		behavior.on_damage(event)

func _on_died(event: DamageEvent) -> void:
	defeated.emit(self, event)
	queue_free()
