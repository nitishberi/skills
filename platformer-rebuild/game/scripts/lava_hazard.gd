extends Area2D
class_name LavaHazard

var _tiles_w: int = 1
var _tiles_h: int = 1

func configure(tiles_w: int, tiles_h: int = 1) -> void:
	_tiles_w = tiles_w
	_tiles_h = tiles_h

func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16 * _tiles_w, 16 * _tiles_h)
	shape.shape = rect
	shape.position = rect.size * 0.5
	add_child(shape)
	for x in _tiles_w:
		for y in _tiles_h:
			var s := Art.make_sprite("lava", false)
			s.position = Vector2(x * 16, y * 16)
			add_child(s)

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		body._die()
