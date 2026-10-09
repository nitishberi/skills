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
var _shell_vis: ColorRect
var _body_vis: ColorRect
var _wing_vis: ColorRect

func _ready() -> void:
	add_to_group("enemies")
	_build_visual()

func _build_visual() -> void:
	_body_vis = ColorRect.new()
	_body_vis.size = Vector2(14, 12)
	_body_vis.position = Vector2(-7, -12)
	_body_vis.color = Color("27ae60") if winged else Color("3d8b6e")
	_body_vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body_vis)
	_shell_vis = ColorRect.new()
	_shell_vis.size = Vector2(14, 10)
	_shell_vis.position = Vector2(-7, -10)
	_shell_vis.color = Color("1e8449") if winged else Color("2f6f4e")
	_shell_vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shell_vis.visible = false
	add_child(_shell_vis)
	_wing_vis = ColorRect.new()
	_wing_vis.size = Vector2(18, 6)
	_wing_vis.position = Vector2(-9, -18)
	_wing_vis.color = Color("d5f5e3")
	_wing_vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wing_vis.visible = winged
	add_child(_wing_vis)

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
				# First stomp clips wings, becomes ground Shellbug
				winged = false
				_wing_vis.visible = false
				_body_vis.color = Color("3d8b6e")
				return
			mode = Mode.SHELL
			_body_vis.visible = false
			_shell_vis.visible = true
		Mode.SHELL:
			mode = Mode.SLIDE
			# kick in player facing; default right if unknown
			var p := get_tree().get_first_node_in_group("player")
			if p and p is Node2D:
				dir = signf((p as Node2D).global_position.x - global_position.x) * -1.0
				if dir == 0.0:
					dir = 1.0
			else:
				dir = 1.0
		Mode.SLIDE:
			mode = Mode.SHELL

func hit_by_ember() -> void:
	if dead:
		return
	dead = true
	RunState.add_score(200)
	queue_free()

func is_shell_idle() -> bool:
	return mode == Mode.SHELL
