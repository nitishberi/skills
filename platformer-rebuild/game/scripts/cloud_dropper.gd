extends CharacterBody2D
class_name CloudDropper

const SPEED := 50.0
var dir: float = -1.0
var _cd: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 12)
	shape.shape = rect
	shape.position = Vector2(0, -6)
	add_child(shape)
	var vis := ColorRect.new()
	vis.size = Vector2(20, 12)
	vis.position = Vector2(-10, -12)
	vis.color = Color("aed6f1")
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vis)

func _physics_process(delta: float) -> void:
	position.x += dir * SPEED * delta
	if position.x < 40 or position.x > 1400:
		dir *= -1.0
	_cd -= delta
	if _cd <= 0.0:
		_cd = 1.6
		_drop()

func _drop() -> void:
	var spike := FallingSpike.new()
	spike.global_position = global_position + Vector2(0, 8)
	get_tree().current_scene.add_child(spike)

func stomp() -> void:
	RunState.add_score(200)
	Sfx.play("stomp")
	queue_free()

func hit_by_ember() -> void:
	stomp()
