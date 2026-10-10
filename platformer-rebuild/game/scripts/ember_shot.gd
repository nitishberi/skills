extends Area2D
class_name EmberShot

const SPEED := 168.0
const LIFE := 2.4
const GRAVITY := 420.0

var dir: float = 1.0
var life: float = LIFE
var bounced: int = 0
var _ground_y: float = 336.0

func _ready() -> void:
	add_to_group("ember_shots")
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)
	add_child(Art.make_sprite("ember_shot", true))
	collision_layer = 0
	collision_mask = 1 | 4

func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	position.x += dir * SPEED * delta
	position.y += GRAVITY * delta
	if position.y >= _ground_y:
		position.y = _ground_y
		if bounced == 0:
			dir *= -1.0
		bounced += 1
		if bounced > 4:
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
	if body is StaticBody2D:
		dir *= -1.0
		bounced += 1
		if bounced > 5:
			queue_free()

func _on_area(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("hit_by_ember"):
			area.hit_by_ember()
		queue_free()
