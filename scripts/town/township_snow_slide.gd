class_name TownshipSnowSlide
extends Area2D
## Narrow blockout behavior for the approved Township snow slide. The slide
## adds a downhill shove while a player is on its packed-snow chute; it does
## not introduce a reusable traversal or vehicle system.

const SLIDE_SPEED: float = 285.0
const META_ACTIVE: StringName = &"township_sliding"

var downhill := Vector2(0.34, 0.94).normalized()

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	process_physics_priority = 50
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	for body: Node2D in get_overlapping_bodies():
		if body is not PenguinPlayer:
			continue
		var player := body as PenguinPlayer
		if player.health == null or not player.health.is_alive():
			continue
		player.set_meta(META_ACTIVE, true)
		player.move_and_collide(downhill * SLIDE_SPEED * delta)
		player.velocity = downhill * SLIDE_SPEED

func _on_body_exited(body: Node2D) -> void:
	if body is PenguinPlayer:
		body.remove_meta(META_ACTIVE)

func _exit_tree() -> void:
	for body: Node2D in get_overlapping_bodies():
		if body is PenguinPlayer:
			body.remove_meta(META_ACTIVE)
