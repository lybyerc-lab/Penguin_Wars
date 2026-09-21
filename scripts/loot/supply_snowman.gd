class_name SupplySnowman
extends Node2D
signal broken(location: Vector2)
@onready var health: Health = $Health

func _ready() -> void:
	add_to_group("breakables")
	health.died.connect(_on_broken)
	health.changed.connect(func(_current: float, _maximum: float) -> void: queue_redraw())

func _on_broken(_event: DamageEvent) -> void:
	broken.emit(global_position)
	queue_free()

func _draw() -> void:
	draw_set_transform(Vector2(0, 17), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 28, Color(0.02, 0.12, 0.2, 0.25))
	draw_set_transform(Vector2.ZERO)
	if health.current < health.maximum:
		draw_rect(Rect2(-19, -55, 38, 4), Color("214358"))
		draw_rect(Rect2(-18, -54, 36 * health.current / health.maximum, 2), Color("c3f5ec"))
