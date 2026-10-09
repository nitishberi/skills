extends Area2D
class_name WaterZone

var _size_px: Vector2 = Vector2(320, 200)

func configure(size_px: Vector2) -> void:
	_size_px = size_px

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = _size_px
	shape.shape = rect
	shape.position = _size_px * 0.5
	add_child(shape)
	var vis := ColorRect.new()
	vis.color = Color(0.2, 0.45, 0.7, 0.35)
	vis.size = _size_px
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vis)

func _on_enter(body: Node) -> void:
	if body is CapPlayer:
		body.in_water = true

func _on_exit(body: Node) -> void:
	if body is CapPlayer:
		body.in_water = false
