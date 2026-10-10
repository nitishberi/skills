extends Area2D
class_name Swimfin
## Underwater fish: Cap cannot stomp in water; ember OK.

var dir: float = -1.0
var speed: float = 50.0
var dead: bool = false
var _base_y: float = 0.0
var _t: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	_base_y = position.y
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 10)
	shape.shape = rect
	add_child(shape)
	add_child(Art.make_sprite("swimfin", true))
	body_entered.connect(_on_body)

func _process(delta: float) -> void:
	if dead:
		return
	_t += delta
	position.x += dir * speed * delta
	position.y = _base_y + sin(_t * 2.0) * 18.0
	if position.x < 40.0 or position.x > 1600.0:
		dir *= -1.0

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		body._take_hit()

func stomp() -> void:
	pass

func hit_by_ember() -> void:
	if dead:
		return
	dead = true
	RunState.add_score(200)
	queue_free()
