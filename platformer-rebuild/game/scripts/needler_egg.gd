extends CharacterBody2D
class_name NeedlerEgg

const GRAVITY := 700.0

var dead: bool = false

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5
	shape.shape = circle
	add_child(shape)
	add_child(Art.make_sprite("needler_egg", true))

func _physics_process(delta: float) -> void:
	if dead:
		return
	velocity.y = minf(400.0, velocity.y + GRAVITY * delta)
	move_and_slide()
	if is_on_floor():
		_hatch()

func stomp() -> void:
	hit_by_ember()

func hit_by_ember() -> void:
	if dead:
		return
	dead = true
	RunState.add_score(200)
	queue_free()

func _hatch() -> void:
	if dead:
		return
	dead = true
	var n := Needler.new()
	n.global_position = global_position
	n.collision_layer = 4
	n.collision_mask = 1
	get_parent().add_child(n)
	queue_free()
