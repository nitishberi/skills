extends Area2D
class_name SpringBoard
## Hop Pad: base bounce; hold jump at compression for max bounce (wiki trampoline).

@export var boost_min: float = -380.0
@export var boost_max: float = -560.0

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
		var hold := Input.is_action_pressed("jump")
		body.velocity.y = boost_max if hold else boost_min
		Sfx.play("jump")
