class_name HerringCache
extends SupplySnowman

const BROKEN: Texture2D = preload("res://assets/discoveries/fcd_herring_cache_broken.png")

func _on_broken(_event: DamageEvent) -> void:
	var decal := Sprite2D.new()
	decal.texture = BROKEN
	decal.scale = Vector2(0.6328, 0.7931)
	decal.offset = Vector2(2, -26)
	decal.position = position
	decal.add_to_group("room_decals")
	get_parent().add_child(decal)
	broken.emit(global_position)
	queue_free()

func _draw() -> void:
	if health.current < health.maximum:
		draw_rect(Rect2(-19, -70, 38, 4), Color("214358"))
		draw_rect(Rect2(-18, -69, 36 * health.current / health.maximum, 2), Color("c3f5ec"))
