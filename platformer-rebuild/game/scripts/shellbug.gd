extends CharacterBody2D
class_name Shellbug

enum Mode { WALK, SHELL, SLIDE }

const WALK_SPEED := 36.0
const SLIDE_SPEED := 200.0
const GRAVITY := 900.0

var dir: float = -1.0
var mode: Mode = Mode.WALK
var dead: bool = false
var winged: bool = false
var _hop_cd: float = 0.0
var _body_sprite: Sprite2D
var _shell_sprite: Sprite2D
var _wing_sprite: Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	_body_sprite = Art.make_sprite("shellbug", true)
	_shell_sprite = Art.make_sprite("shellbug_shell", true)
	_shell_sprite.visible = false
	_wing_sprite = Art.make_sprite("wing", true)
	_wing_sprite.position = Vector2(0, -10)
	_wing_sprite.visible = winged
	add_child(_body_sprite)
	add_child(_shell_sprite)
	add_child(_wing_sprite)
	_sync_visual()

func _sync_visual() -> void:
	_body_sprite.visible = mode == Mode.WALK
	_shell_sprite.visible = mode != Mode.WALK
	_wing_sprite.visible = winged and mode == Mode.WALK

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	match mode:
		Mode.WALK:
			velocity.x = dir * WALK_SPEED
			if is_on_wall():
				dir *= -1.0
			if winged:
				_hop_cd -= delta
				if is_on_floor() and _hop_cd <= 0.0:
					velocity.y = -220.0
					_hop_cd = 0.9
		Mode.SHELL:
			velocity.x = 0.0
		Mode.SLIDE:
			velocity.x = dir * SLIDE_SPEED
			if is_on_wall():
				dir *= -1.0
	move_and_slide()
	_hit_others()

func _hit_others() -> void:
	if mode != Mode.SLIDE:
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var other := col.get_collider()
		if other == null:
			continue
		if other.is_in_group("enemies") and other != self:
			if other.has_method("hit_by_ember"):
				other.hit_by_ember()
			elif other.has_method("stomp"):
				other.stomp()
			RunState.add_score(200)

func stomp() -> void:
	if dead:
		return
	match mode:
		Mode.WALK:
			if winged:
				winged = false
				_sync_visual()
				return
			mode = Mode.SHELL
			_sync_visual()
		Mode.SHELL:
			mode = Mode.SLIDE
			var p := get_tree().get_first_node_in_group("player")
			if p and p is Node2D:
				dir = signf((p as Node2D).global_position.x - global_position.x) * -1.0
				if dir == 0.0:
					dir = 1.0
			else:
				dir = 1.0
		Mode.SLIDE:
			mode = Mode.SHELL
	_sync_visual()

func hit_by_ember() -> void:
	if dead:
		return
	dead = true
	RunState.add_score(200)
	queue_free()

func is_shell_idle() -> bool:
	return mode == Mode.SHELL
