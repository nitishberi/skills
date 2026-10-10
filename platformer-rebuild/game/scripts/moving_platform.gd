extends AnimatableBody2D
class_name MovingPlatform

@export var travel: Vector2 = Vector2(64, 0)
@export var period: float = 2.5

var _origin: Vector2
var _t: float = 0.0

func _ready() -> void:
	_origin = position
	collision_layer = 1
	collision_mask = 0
	# Hard Quest: shorter lifts (wiki wide→narrow).
	var w := 32.0 if RunState.hard_quest else 48.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, 12)
	shape.shape = rect
	shape.position = Vector2(w * 0.5, 6)
	add_child(shape)
	var spr := Art.make_sprite("mover", false)
	if RunState.hard_quest:
		spr.scale.x = 0.67
	add_child(spr)

func _physics_process(delta: float) -> void:
	_t += delta
	var u := (sin(_t * TAU / period) + 1.0) * 0.5
	position = _origin + travel * u
