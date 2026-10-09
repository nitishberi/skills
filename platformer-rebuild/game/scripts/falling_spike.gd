extends Area2D
class_name FallingSpike

var fall_speed := 120.0

func _ready() -> void:
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	add_to_group("hazards")
	if not body_entered.is_connected(_on_body):
		body_entered.connect(_on_body)
	if get_child_count() == 0:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 5
		shape.shape = circle
		add_child(shape)
		var vis := ColorRect.new()
		vis.size = Vector2(10, 10)
		vis.position = Vector2(-5, -5)
		vis.color = Color("922b21")
		vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(vis)

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	if position.y > 420:
		queue_free()

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		body._die()
