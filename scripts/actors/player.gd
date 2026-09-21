class_name PenguinPlayer
extends CharacterBody2D

@export var identity: PlayerIdentity
@export var speed: float = 220.0
var arena_bounds := Rect2(-540, -260, 1080, 520)
@onready var health: Health = $Health
@onready var experience: Experience = $Experience
@onready var input_source: LocalPlayerInput = $LocalInput
@onready var weapon: WeaponController = $Weapon

func _ready() -> void:
	assert(identity != null, "Set identity before adding a player to the tree")
	input_source.identity = identity
	weapon.wielder = self
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)

func _physics_process(_delta: float) -> void:
	velocity = input_source.movement() * speed if health.is_alive() else Vector2.ZERO
	move_and_slide()
	global_position = global_position.clamp(arena_bounds.position, arena_bounds.end)

func apply_upgrade(upgrade: UpgradeDefinition) -> void:
	match upgrade.stat:
		UpgradeDefinition.Stat.DAMAGE:
			weapon.damage_bonus += upgrade.amount
		UpgradeDefinition.Stat.SPEED:
			speed = maxf(1.0, speed + upgrade.amount)
		UpgradeDefinition.Stat.MAX_HEALTH:
			health.maximum = maxf(1.0, health.maximum + upgrade.amount)
			health.heal(maxf(0.0, upgrade.amount))

func _on_health_changed(_current: float, _maximum: float) -> void:
	queue_redraw()

func _on_died(_event: DamageEvent) -> void:
	collision_layer = 0
	collision_mask = 0
	queue_redraw()

func _draw() -> void:
	var color: Color = identity.tint if identity != null else Color.WHITE
	if health != null and not health.is_alive():
		color = Color("526273")
	draw_circle(Vector2(0, 10), 20, Color(0, 0, 0, 0.22))
	draw_circle(Vector2.ZERO, 20, color)
	draw_circle(Vector2(0, 1), 15, Color("152438"))
	draw_circle(Vector2(0, 5), 10, Color("f0f7ec"))
	draw_circle(Vector2(-5, -6), 3, Color.WHITE)
	draw_circle(Vector2(5, -6), 3, Color.WHITE)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -1), Vector2(4, -1), Vector2(0, 5)]), Color("ffbf69"))
	if health != null:
		draw_rect(Rect2(-20, -31, 40, 4), Color("243648"))
		draw_rect(Rect2(-20, -31, 40 * health.current / health.maximum, 4), color)
