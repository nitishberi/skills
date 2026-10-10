extends CharacterBody2D
class_name TossTwin
## Hammer thrower; hops in place and lobbs harmful arcs.

const GRAVITY := 900.0

var dir: float = -1.0
var _throw_cd: float = 1.0
var _hop_cd: float = 0.6
var dead: bool = false
var on_screen_t: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	if not has_node("CollisionShape2D"):
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(14, 20)
		shape.shape = rect
		shape.position = Vector2(0, -10)
		add_child(shape)
	add_child(Art.make_sprite("toss_twin", true))

func _physics_process(delta: float) -> void:
	if dead:
		return
	on_screen_t += delta
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_hop_cd -= delta
	if is_on_floor() and _hop_cd <= 0.0:
		velocity.y = -160.0
		_hop_cd = 1.1
	# After long on-screen time, start chasing Cap (wiki Hammer Bro pattern).
	if on_screen_t > 12.0:
		var p := get_tree().get_first_node_in_group("player")
		if p and p is Node2D:
			dir = signf((p as Node2D).global_position.x - global_position.x)
			if dir == 0.0:
				dir = -1.0
			velocity.x = dir * 40.0
	else:
		velocity.x = 0.0
	move_and_slide()
	_throw_cd -= delta
	if _throw_cd <= 0.0:
		_throw_cd = 1.35
		_lob()

func _lob() -> void:
	var h := TossHammer.new()
	h.global_position = global_position + Vector2(dir * 8.0, -18.0)
	h.velocity = Vector2(dir * 90.0, -220.0)
	get_tree().current_scene.add_child(h)

func stomp() -> void:
	if dead:
		return
	dead = true
	RunState.add_score(1000)
	queue_free()

func hit_by_ember() -> void:
	stomp()
