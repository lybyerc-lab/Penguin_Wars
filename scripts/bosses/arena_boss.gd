class_name ArenaBoss
extends ArenaEnemy
var definition: BossDefinition
var difficulty: float = 1.0

func configure(data: BossDefinition, multiplier: float, party_size: int) -> void:
	definition = data
	difficulty = multiplier
	get_node("Health").maximum = data.maximum_health * multiplier * (1.0 + 0.65 * maxi(0, party_size - 1))
	contact_damage = data.damage * multiplier
	hit_radius = 21.0 * data.visual_scale
	contact_radius = hit_radius + 18
	knockback_multiplier = 0.08
	var shape := CircleShape2D.new()
	shape.radius = hit_radius * 0.65
	get_node("CollisionShape2D").shape = shape

func _ready() -> void:
	super._ready()
	get_node("CharacterVisual").scale = Vector2.ONE * definition.visual_scale

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if definition == null or behavior == null:
		return
	var attack := behavior as BossBehavior
	var crown_y: float = -48 * definition.visual_scale
	draw_colored_polygon(PackedVector2Array([Vector2(-23, crown_y), Vector2(-28, crown_y - 22), Vector2(-10, crown_y - 10), Vector2(0, crown_y - 32), Vector2(10, crown_y - 10), Vector2(28, crown_y - 22), Vector2(23, crown_y)]), definition.tint)
	draw_arc(Vector2.ZERO, hit_radius, 0, TAU, 48, definition.tint, 3)
	if attack.state == BossBehavior.State.WINDUP:
		var color: Color = definition.tint
		if attack.attack == BossBehavior.Attack.RUSH:
			var side := attack.direction.orthogonal() * contact_radius
			draw_colored_polygon(PackedVector2Array([-side, side, side + attack.direction * 310, -side + attack.direction * 310]), Color(color, 0.23))
			draw_line(Vector2.ZERO, attack.direction * 310, color, 3)
		elif attack.attack == BossBehavior.Attack.SLAM:
			draw_circle(Vector2.ZERO, attack.slam_radius, Color(color, 0.15))
			draw_arc(Vector2.ZERO, attack.slam_radius, 0, TAU, 64, color, 4)
		else:
			for index: int in range(attack.shot_count()):
				var direction := Vector2.RIGHT.rotated(attack.direction.angle() + TAU * index / attack.shot_count())
				draw_line(direction * hit_radius, direction * (hit_radius + 85), color, 3)
	if attack.enraged:
		draw_arc(Vector2.ZERO, hit_radius + 8, 0, TAU, 48, Color("ff7060"), 3)
