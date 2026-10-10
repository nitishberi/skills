extends Area2D
class_name EmberBlob
## Vertical lava hopper.

var _base: Vector2
var _t: float = 0.0

func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	_base = position
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7
	shape.shape = circle
	add_child(shape)
	add_child(Art.make_sprite("ember_blob", true))
	body_entered.connect(_on_body)

func _process(delta: float) -> void:
	_t += delta
	var u := absf(sin(_t * 1.6))
	position.y = _base.y - u * 72.0
	monitoring = u > 0.15

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		body._die()
