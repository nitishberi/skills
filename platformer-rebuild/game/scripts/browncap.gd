extends CharacterBody2D
class_name Browncap

const SPEED := 40.0
const GRAVITY := 900.0

var dir: float = -1.0
var dead: bool = false

func _ready() -> void:
	add_to_group("enemies")
	if RunState.hard_quest:
		set_meta("speed_mul", SmbTuning.HARD_ENEMY_SPEED_MUL)
	var s := Art.make_sprite("mudbit", true)
	add_child(s)

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
	if dead:
		return
	dead = true
	collision_layer = 0
	collision_mask = 0
	queue_free()

func hit_by_ember() -> void:
	stomp()
	RunState.add_score(100)
