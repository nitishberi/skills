extends CharacterBody2D
class_name Needler
## Spiky crawler: stomping hurts Cap; ember / shell / star OK.

const SPEED := 42.0
const GRAVITY := 900.0

var dir: float = -1.0
var dead: bool = false

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("needlers")
	if RunState.hard_quest:
		set_meta("speed_mul", SmbTuning.HARD_ENEMY_SPEED_MUL)
	if not has_node("CollisionShape2D"):
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(14, 12)
		shape.shape = rect
		shape.position = Vector2(0, -6)
		add_child(shape)
	add_child(Art.make_sprite("needler", true))

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var mul := float(get_meta("speed_mul", 1.0))
	velocity.x = dir * SPEED * mul
	move_and_slide()
	if is_on_wall():
		dir *= -1.0

func stomp() -> void:
	# Spiky: stomp damages the player (handled by Cap); Needler ignores stomp KOs.
	pass

func hit_by_ember() -> void:
	if dead:
		return
	dead = true
	RunState.add_score(200)
	queue_free()

func is_stomp_safe() -> bool:
	return false
