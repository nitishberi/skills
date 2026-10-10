extends Area2D
class_name HazardPlant

var _t: float = 0.0
var _base: Vector2
var _sprite: Sprite2D
var pipe_x: float = 0.0

func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body)
	_base = position
	pipe_x = position.x
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 16)
	shape.shape = rect
	shape.position = Vector2(0, -8)
	add_child(shape)
	_sprite = Art.make_sprite("plant", true)
	add_child(_sprite)

func _player_near_pipe() -> bool:
	var p := get_tree().get_first_node_in_group("player")
	if p == null or not (p is Node2D):
		return false
	var px := (p as Node2D).global_position.x
	var py := (p as Node2D).global_position.y
	# Hide while Cap stands on/beside the pipe mouth.
	return absf(px - pipe_x) < 22.0 and py > _base.y - 40.0

func _process(delta: float) -> void:
	_t += delta
	var phase := fmod(_t, 2.4)
	var want_up := phase < 1.1 and not _player_near_pipe()
	position.y = _base.y + (-18.0 if want_up else 8.0)
	_sprite.visible = want_up
	monitoring = want_up

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		body._die()
