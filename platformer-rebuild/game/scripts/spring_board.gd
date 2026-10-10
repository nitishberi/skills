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
	add_child(Art.make_sprite("spring", false))

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		body.velocity.y = boost
		Sfx.play("jump")
