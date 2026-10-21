extends Area2D
class_name TossHammer

var velocity: Vector2 = Vector2.ZERO
var life: float = 2.5

func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5
	shape.shape = circle
	add_child(shape)
	add_child(Art.make_sprite("hammer", true))
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	velocity.y += 520.0 * delta
	position += velocity * delta
	life -= delta
	if life <= 0.0 or position.y > 420.0:
		queue_free()

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		body._take_hit()
		queue_free()
