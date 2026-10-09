extends Node2D
class_name FireBar

@export var arm_count: int = 4
@export var spacing: float = 14.0
@export var spin_speed: float = 1.6

func _ready() -> void:
	for i in range(arm_count):
		var ball := Area2D.new()
		ball.collision_layer = 16
		ball.collision_mask = 2
		ball.monitoring = true
		ball.add_to_group("hazards")
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 5
		shape.shape = circle
		ball.add_child(shape)
		var vis := ColorRect.new()
		vis.size = Vector2(10, 10)
		vis.position = Vector2(-5, -5)
		vis.color = Color("e74c3c")
		vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ball.add_child(vis)
		ball.position = Vector2((i + 1) * spacing, 0)
		ball.body_entered.connect(_on_ball_body)
		add_child(ball)
	# hub
	var hub := ColorRect.new()
	hub.size = Vector2(8, 8)
	hub.position = Vector2(-4, -4)
	hub.color = Color("f5b041")
	hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hub)

func _process(delta: float) -> void:
	rotation += spin_speed * delta

func _on_ball_body(body: Node) -> void:
	if body is CapPlayer:
		body._die()
