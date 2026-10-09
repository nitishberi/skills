extends CharacterBody2D
class_name Browncap

const SPEED := 40.0
const GRAVITY := 900.0

var dir: float = -1.0
var dead: bool = false

func _ready() -> void:
	add_to_group("enemies")
	_build_visual()

func _build_visual() -> void:
	var body := ColorRect.new()
	body.size = Vector2(14, 14)
	body.position = Vector2(-7, -14)
	body.color = Color("8d6e63")
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	var eye := ColorRect.new()
	eye.size = Vector2(3, 3)
	eye.position = Vector2(-2, -11)
	eye.color = Color("fff3e0")
	eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(eye)

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = dir * SPEED
	move_and_slide()
	if is_on_wall():
		dir *= -1.0

func stomp() -> void:
	if dead:
		return
	dead = true
	collision_layer = 0
	collision_mask = 0
	queue_free()

func hit_by_ember() -> void:
	stomp()
	RunState.add_score(100)
