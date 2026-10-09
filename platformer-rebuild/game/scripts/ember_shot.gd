extends Area2D
class_name EmberShot

const SPEED := 220.0
const LIFE := 2.2

var dir: float = 1.0
var life: float = LIFE
var bounced: int = 0

func _ready() -> void:
	add_to_group("ember_shots")
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)
	_build_visual()
	collision_layer = 0
	collision_mask = 1 | 4 # world + enemies

func _build_visual() -> void:
	var v := ColorRect.new()
	v.size = Vector2(8, 8)
	v.position = Vector2(-4, -4)
	v.color = Color("e76f51")
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)

func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	position.x += dir * SPEED * delta
	position.y += 40.0 * delta
	if position.y > 400.0:
		queue_free()

func _on_body(body: Node) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("hit_by_ember"):
			body.hit_by_ember()
		elif body.has_method("stomp"):
			body.stomp()
			RunState.add_score(100)
		queue_free()
		return
	# world bounce a couple times then die
	if body is StaticBody2D:
		bounced += 1
		dir *= -1.0
		position.y -= 6.0
		if bounced > 3:
			queue_free()

func _on_area(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("hit_by_ember"):
			area.hit_by_ember()
		queue_free()
