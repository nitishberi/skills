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
	var tw := int(_size_px.x / 16)
	var th := int(_size_px.y / 16)
	for x in tw:
		for y in th:
			var s := Art.make_sprite("water", false)
			s.position = Vector2(x * 16, y * 16)
			add_child(s)

func _on_enter(body: Node) -> void:
	if body is CapPlayer:
		body.in_water = true

func _on_exit(body: Node) -> void:
	if body is CapPlayer:
		body.in_water = false
