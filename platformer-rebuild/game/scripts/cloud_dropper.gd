extends CharacterBody2D
class_name CloudDropper
## Sky Rider: follows Cap X, drops Needler Eggs, respawns after defeat until flag.

const SPEED := 70.0

var dir: float = -1.0
var _cd: float = 0.0
var chasing: bool = true
var _origin: Vector2

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("sky_riders")
	collision_layer = 4
	collision_mask = 0
	_origin = global_position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 12)
	shape.shape = rect
	shape.position = Vector2(0, -6)
	add_child(shape)
	var s := Art.make_sprite("sky_rider", true)
	s.scale = Vector2(0.55, 0.55)
	add_child(s)

func stop_chase() -> void:
	chasing = false

func _physics_process(delta: float) -> void:
	if not chasing:
		return
	var p := get_tree().get_first_node_in_group("player")
	if p and p is Node2D:
		var tx := (p as Node2D).global_position.x
		global_position.x = move_toward(global_position.x, tx, SPEED * delta)
		dir = signf(tx - global_position.x)
		if dir == 0.0:
			dir = -1.0
	_cd -= delta
	if _cd <= 0.0:
		_cd = 1.7
		_drop()

func _drop() -> void:
	var egg := NeedlerEgg.new()
	egg.global_position = global_position + Vector2(0, 8)
	egg.velocity = Vector2(dir * 30.0, 50.0)
	get_tree().current_scene.add_child(egg)

func stomp() -> void:
	RunState.add_score(800)
	Sfx.play("stomp")
	# Wiki: Lakitu respawns after defeat.
	var parent := get_parent()
	var respawn_pos := _origin
	queue_free()
	if parent:
		var t := parent.get_tree().create_timer(2.4)
		t.timeout.connect(func() -> void:
			if not is_instance_valid(parent):
				return
			var c := CloudDropper.new()
			c.global_position = respawn_pos
			parent.add_child(c)
		)

func hit_by_ember() -> void:
	stomp()
