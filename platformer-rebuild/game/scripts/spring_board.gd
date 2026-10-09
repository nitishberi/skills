extends Area2D
class_name SpringBoard

@export var boost: float = -520.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 8)
	shape.shape = rect
	shape.position = Vector2(8, 12)
	add_child(shape)
	var vis := ColorRect.new()
	vis.size = Vector2(16, 6)
	vis.position = Vector2(0, 10)
	vis.color = Color("e74c3c")
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vis)
	var top := ColorRect.new()
	top.size = Vector2(16, 4)
	top.position = Vector2(0, 6)
	top.color = Color("f5b7b1")
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		body.velocity.y = boost
		Sfx.play("jump")
