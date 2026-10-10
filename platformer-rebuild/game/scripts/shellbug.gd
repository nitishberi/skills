extends CharacterBody2D
class_name Shellbug

enum Mode { WALK, SHELL, SLIDE }
enum Flight { NONE, HOP, VERTICAL }

const WALK_SPEED := 36.0
const SLIDE_SPEED := 200.0
const GRAVITY := 900.0

func _speed_mul() -> float:
	return float(get_meta("speed_mul", 1.0))

var dir: float = -1.0
var mode: Mode = Mode.WALK
var dead: bool = false
var winged: bool = false
var flight: int = Flight.NONE
var cliff_turn: bool = false ## Red "Cliffbug": turn at ledges
var fireproof: bool = false ## "Ashbug": immune to ember
var combo: int = 0
var _hop_cd: float = 0.0
var _hover_origin_y: float = 0.0
var _hover_t: float = 0.0
var _body_sprite: Sprite2D
var _shell_sprite: Sprite2D
var _wing_sprite: Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	if RunState.hard_quest:
		set_meta("speed_mul", SmbTuning.HARD_ENEMY_SPEED_MUL)
	if winged and flight == Flight.NONE:
		flight = Flight.HOP
	_hover_origin_y = position.y
	var body_key := "ashbug" if fireproof else ("cliffbug" if cliff_turn else "shellbug")
	var shell_key := "ashbug_shell" if fireproof else "shellbug_shell"
	_body_sprite = Art.make_sprite(body_key, true)
	_shell_sprite = Art.make_sprite(shell_key, true)
	_shell_sprite.visible = false
	_wing_sprite = Art.make_sprite("wing", true)
	_wing_sprite.position = Vector2(0, -10)
	_wing_sprite.visible = winged
	add_child(_body_sprite)
	add_child(_shell_sprite)
	add_child(_wing_sprite)
	_sync_visual()

func _sync_visual() -> void:
	_body_sprite.visible = mode == Mode.WALK or flight == Flight.VERTICAL
	_shell_sprite.visible = mode != Mode.WALK and flight != Flight.VERTICAL
	_wing_sprite.visible = winged and mode == Mode.WALK

func _physics_process(delta: float) -> void:
	if dead:
		return
	if flight == Flight.VERTICAL and mode == Mode.WALK:
		_hover_t += delta
		var target_y := _hover_origin_y + sin(_hover_t * 2.2) * 36.0
		velocity = Vector2(0.0, (target_y - position.y) / maxf(delta, 0.001))
		move_and_slide()
		position.y = target_y
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	match mode:
		Mode.WALK:
			velocity.x = dir * WALK_SPEED * _speed_mul()
			if is_on_wall():
				dir *= -1.0
			elif cliff_turn and is_on_floor() and _ledge_ahead():
				dir *= -1.0
			if winged and flight == Flight.HOP:
				_hop_cd -= delta
				if is_on_floor() and _hop_cd <= 0.0:
					velocity.y = -220.0
					_hop_cd = 0.9
		Mode.SHELL:
			velocity.x = 0.0
		Mode.SLIDE:
			velocity.x = dir * SLIDE_SPEED * _speed_mul()
			if is_on_wall():
				dir *= -1.0
	move_and_slide()
	_hit_others()

func _ledge_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(dir * 10.0, -2.0)
	var to := from + Vector2(0, 20.0)
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collision_mask = 1
	q.exclude = [self]
	return space.intersect_ray(q).is_empty()

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
			combo += 1
			var pts := 100
			match mini(combo, 5):
				1:
					pts = 200
				2:
					pts = 400
				3:
					pts = 800
				4:
					pts = 1000
				_:
					pts = 2000
			RunState.add_score(pts)

func stomp() -> void:
	if dead:
		return
	match mode:
		Mode.WALK:
			if winged or flight == Flight.VERTICAL:
				winged = false
				flight = Flight.NONE
				_sync_visual()
				return
			mode = Mode.SHELL
			combo = 0
			_sync_visual()
		Mode.SHELL:
			mode = Mode.SLIDE
			combo = 0
			var p := get_tree().get_first_node_in_group("player")
			if p and p is Node2D:
				dir = signf((p as Node2D).global_position.x - global_position.x) * -1.0
				if dir == 0.0:
					dir = 1.0
			else:
				dir = 1.0
		Mode.SLIDE:
			mode = Mode.SHELL
			combo = 0
	_sync_visual()

func hit_by_ember() -> void:
	if dead:
		return
	if fireproof:
		return
	dead = true
	RunState.add_score(200)
	queue_free()

func is_shell_idle() -> bool:
	return mode == Mode.SHELL
