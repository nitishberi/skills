extends Area2D
class_name Inkjet
## Erratic underwater squid; chase Cap loosely.

var dead: bool = false
var speed: float = 55.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 16)
	shape.shape = rect
	add_child(shape)
	add_child(Art.make_sprite("inkjet", true))
	body_entered.connect(_on_body)

func _process(delta: float) -> void:
	if dead:
		return
	var p := get_tree().get_first_node_in_group("player")
	if p and p is Node2D:
		var target := (p as Node2D).global_position + Vector2(0, -40)
		global_position = global_position.move_toward(target, speed * delta)

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
