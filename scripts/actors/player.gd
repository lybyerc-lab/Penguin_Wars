class_name PenguinPlayer
extends CharacterBody2D

@export var identity: PlayerIdentity
@export var speed: float = 220.0
var arena_bounds := Rect2(-540, -260, 1080, 520)
var stats := PlayerStats.new()
var _live_layer: int = 0
var _live_mask: int = 0
@onready var health: Health = $Health
@onready var experience: Experience = $Experience
@onready var input_source: LocalPlayerInput = $LocalInput
@onready var weapon_rack: WeaponRack = $WeaponRack
@onready var dash: DashController = $Dash

## Compatibility view of slot 0. New code that owns inventory should use
## weapon_rack; current combat, town and test seams still refer to the active
## starting weapon through this narrow accessor.
var weapon: WeaponController:
	get:
		return weapon_rack.controller_at(0) if weapon_rack != null else null

func _ready() -> void:
	assert(identity != null, "Set identity before adding a player to the tree")
	input_source.identity = identity
	weapon_rack.setup(self)
	health.defenses = stats
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	health.revived.connect(_on_revived)
	_live_layer = collision_layer
	_live_mask = collision_mask

func _physics_process(delta: float) -> void:
	var movement: Vector2 = input_source.movement()
	dash.tick(delta, movement, input_source.dash_requested(), health.is_alive())
	health.invulnerable = dash.is_active()
	velocity = movement * speed if health.is_alive() else Vector2.ZERO
	if dash.is_active():
		velocity = dash.direction * dash.burst_speed
	move_and_slide()
	global_position = global_position.clamp(arena_bounds.position, arena_bounds.end)
	queue_redraw()
	if health.is_alive() and stats.regeneration > 0.0:
		health.heal(stats.regeneration * delta)

func apply_upgrade(upgrade: UpgradeDefinition) -> void:
	match upgrade.stat:
		UpgradeDefinition.Stat.DAMAGE:
			stats.flat_weapon_damage += upgrade.amount
		UpgradeDefinition.Stat.SPEED:
			speed = maxf(1.0, speed + upgrade.amount)
		UpgradeDefinition.Stat.MAX_HEALTH:
			health.maximum = maxf(1.0, health.maximum + upgrade.amount)
			health.heal(maxf(0.0, upgrade.amount))
		UpgradeDefinition.Stat.HARVEST:
			stats.harvest_multiplier = maxf(1.0, stats.harvest_multiplier + upgrade.amount)
		_:
			var fields: Dictionary = {UpgradeDefinition.Stat.ARMOR: "armor", UpgradeDefinition.Stat.REGENERATION: "regeneration", UpgradeDefinition.Stat.DAMAGE_PERCENT: "damage_percent", UpgradeDefinition.Stat.MELEE_DAMAGE: "melee_damage", UpgradeDefinition.Stat.RANGED_DAMAGE: "ranged_damage", UpgradeDefinition.Stat.ATTACK_SPEED: "attack_speed", UpgradeDefinition.Stat.CRITICAL_CHANCE: "critical_chance", UpgradeDefinition.Stat.DODGE: "dodge_chance", UpgradeDefinition.Stat.PICKUP_RANGE: "pickup_bonus", UpgradeDefinition.Stat.ENGINEERING: "engineering", UpgradeDefinition.Stat.RANGE: "range_bonus"}
			if fields.has(upgrade.stat):
				var field: String = fields[upgrade.stat]
				stats.set(field, float(stats.get(field)) + upgrade.amount)

func configure_weapon_loadout(definitions: Array[WeaponDefinition], capacity: int = WeaponRack.DEFAULT_CAPACITY) -> void:
	var rack := get_node_or_null("WeaponRack") as WeaponRack
	if rack != null:
		rack.configure_loadout(definitions, capacity)

func _on_health_changed(_current: float, _maximum: float) -> void:
	queue_redraw()

func _on_died(_event: DamageEvent) -> void:
	collision_layer = 0
	collision_mask = 0
	queue_redraw()

func _on_revived(_current: float) -> void:
	collision_layer = _live_layer
	collision_mask = _live_mask
	queue_redraw()

func _draw() -> void:
	if dash != null and dash.is_active():
		for index: int in range(1, 4):
			draw_circle(-dash.direction * index * 15.0, 20 - index * 3, Color(0.6, 0.95, 1.0, 0.4 / index))
		draw_arc(Vector2.ZERO, 24, 0, TAU, 24, Color("d4fbff"), 2)
	var color: Color = identity.tint if identity != null else Color.WHITE
	if health != null and not health.is_alive():
		return
	if health != null:
		draw_rect(Rect2(-21, -46, 42, 6), Color("152a3e"))
		draw_rect(Rect2(-20, -45, 40 * health.current / health.maximum, 4), color)
