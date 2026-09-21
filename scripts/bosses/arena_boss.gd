class_name ArenaBoss
extends BossActor
## Concrete boss actor implementing visual telegraphs, scaling, and presentation.

func configure(definition: BossDefinition, party_size: int) -> void:
	super(definition, party_size)
	if definition == null:
		return
	hit_radius = definition.hit_radius
	contact_radius = hit_radius + 18.0
	knockback_multiplier = 0.08
	var shape := CircleShape2D.new()
	shape.radius = hit_radius * 0.65
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null:
		col.shape = shape

func _ready() -> void:
	super._ready()
	if boss_definition != null:
		var vis := get_node_or_null("CharacterVisual") as Node2D
		if vis != null:
			vis.scale = Vector2.ONE * boss_definition.visual_scale

func _process(_delta: float) -> void:
	queue_redraw()

func title() -> String:
	return boss_definition.display_name if boss_definition != null else "Boss"

func phase() -> String:
	var brain := behavior as BossBehavior
	return "ENRAGED" if brain != null and brain.enraged else ""

func _draw() -> void:
	if boss_definition == null or behavior == null:
		return
	var attack := behavior as BossBehavior
	if attack == null:
		return
	var crown_y: float = -48.0 * boss_definition.visual_scale
	draw_colored_polygon(PackedVector2Array([
		Vector2(-23, crown_y),
		Vector2(-28, crown_y - 22),
		Vector2(-10, crown_y - 10),
		Vector2(0, crown_y - 32),
		Vector2(10, crown_y - 10),
		Vector2(28, crown_y - 22),
		Vector2(23, crown_y)
	]), boss_definition.tint)
	draw_arc(Vector2.ZERO, hit_radius, 0, TAU, 48, boss_definition.tint, 3)
	if attack.state == BossBehavior.State.WINDUP:
		var color: Color = boss_definition.tint
		if attack.attack == BossBehavior.Attack.RUSH:
			var side: Vector2 = attack.direction.orthogonal() * contact_radius
			draw_colored_polygon(PackedVector2Array([
				-side, side, side + attack.direction * BossBehavior.RUSH_LANE, -side + attack.direction * BossBehavior.RUSH_LANE
			]), Color(color, 0.23))
			draw_line(Vector2.ZERO, attack.direction * BossBehavior.RUSH_LANE, color, 3)
		elif attack.attack == BossBehavior.Attack.SLAM:
			draw_circle(Vector2.ZERO, attack.slam_radius, Color(color, 0.15))
			draw_arc(Vector2.ZERO, attack.slam_radius, 0, TAU, 64, color, 4)
		else:
			for index: int in range(attack.shot_count()):
				var dir := Vector2.RIGHT.rotated(attack.direction.angle() + TAU * index / attack.shot_count())
				draw_line(dir * hit_radius, dir * (hit_radius + 85.0), color, 3)
	if attack.enraged:
		draw_arc(Vector2.ZERO, hit_radius + 8.0, 0, TAU, 48, Color("ff7060"), 3)
