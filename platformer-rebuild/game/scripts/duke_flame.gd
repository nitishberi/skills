extends Area2D
class_name DukeFlame
## Horizontal boss flame; transcends walls (wiki Koopa fire).

var dir: float = -1.0
var life: float = 3.5

func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 8)
	shape.shape = rect
	add_child(shape)
	add_child(Art.make_sprite("duke_flame", true))
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	position.x += dir * 110.0 * delta
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		body._die()
