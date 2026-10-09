extends Area2D
class_name HazardPlant

var _t: float = 0.0
var _base: Vector2
var _vis: ColorRect

func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body)
	_base = position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 16)
	shape.shape = rect
	shape.position = Vector2(0, -8)
	add_child(shape)
	_vis = ColorRect.new()
	_vis.size = Vector2(12, 16)
	_vis.position = Vector2(-6, -16)
	_vis.color = Color("196f3d")
	_vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vis)

func _process(delta: float) -> void:
	_t += delta
	# Peek cycle: hidden then up
	var phase := fmod(_t, 2.4)
	var up := phase < 1.1
	position.y = _base.y + (-18.0 if up else 8.0)
	_vis.visible = up
	monitoring = up

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		body._die()
