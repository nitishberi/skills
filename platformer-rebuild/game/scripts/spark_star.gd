extends CharacterBody2D
class_name SparkStar
## Star: pops out, then bounces along the ground / reverses on walls (SMB-style).

const WALK_SPEED := 90.0
const GRAVITY := 980.0
const MAX_FALL := 420.0
const POP_V := -200.0
const BOUNCE_V := -220.0

var collected: bool = false
var move_dir: float = 1.0

func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 8
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 12)
	shape.shape = rect
	shape.position = Vector2(0, -6)
	add_child(shape)
	var s := Art.make_sprite("star", true)
	add_child(s)
	var tw := create_tween().set_loops()
	tw.tween_property(s, "scale", Vector2(1.15, 1.15), 0.35)
	tw.tween_property(s, "scale", Vector2(1.0, 1.0), 0.35)
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	sensor.monitoring = true
	var sshape := CollisionShape2D.new()
	var srect := RectangleShape2D.new()
	srect.size = Vector2(14, 14)
	sshape.shape = srect
	sshape.position = Vector2(0, -6)
	sensor.add_child(sshape)
	sensor.body_entered.connect(_on_sensor_body)
	add_child(sensor)
	velocity = Vector2(move_dir * WALK_SPEED, POP_V)

func _physics_process(delta: float) -> void:
	if collected:
		return
	velocity.y = minf(MAX_FALL, velocity.y + GRAVITY * delta)
	velocity.x = move_dir * WALK_SPEED
	move_and_slide()
	if is_on_floor():
		velocity.y = BOUNCE_V
	if is_on_wall():
		move_dir *= -1.0
		velocity.x = move_dir * WALK_SPEED
	for i in get_slide_collision_count():
		var body := get_slide_collision(i).get_collider()
		if body is CapPlayer:
			collect(body)
	if global_position.y > 440.0:
		queue_free()

func _on_sensor_body(body: Node) -> void:
	if body is CapPlayer:
		collect(body)

func collect(player: Node) -> void:
	if collected:
		return
	collected = true
	if player.has_method("grant_invuln"):
		player.grant_invuln()
	queue_free()
