extends CharacterBody2D
class_name GlidePowerup
## SMB-style: pop out of block, then walk on ground; reverse on solid walls; fall in gaps.

const WALK_SPEED := 55.0
const GRAVITY := 980.0
const MAX_FALL := 420.0
const POP_V := -160.0

var collected: bool = false
var move_dir: float = 1.0
var _emerging: bool = true
var _emerge_t: float = 0.18
var _sprite: Sprite2D

func _powerup_ready(sprite_key: String) -> void:
	add_to_group("pickups")
	collision_layer = 8
	# World solids only (not enemies). Player collects via Cap slide + Area sensor.
	collision_mask = 1
	if not has_node("CollisionShape2D"):
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = Vector2(12, 12)
		shape.shape = rect
		shape.position = Vector2(0, -6)
		add_child(shape)
	_sprite = Art.make_sprite(sprite_key, true)
	add_child(_sprite)
	# Sensor so a standing Cap still picks up a mushroom that walks into them.
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
	velocity = Vector2(0.0, POP_V)

func _physics_process(delta: float) -> void:
	if collected:
		return
	if _emerging:
		_emerge_t -= delta
		velocity.y = minf(MAX_FALL, velocity.y + GRAVITY * delta)
		move_and_slide()
		if _emerge_t <= 0.0 or is_on_floor():
			_emerging = false
			velocity.x = move_dir * WALK_SPEED
		_try_collect_from_slides()
		_cull_if_fallen()
		return
	if not is_on_floor():
		velocity.y = minf(MAX_FALL, velocity.y + GRAVITY * delta)
	else:
		velocity.y = 0.0
	velocity.x = move_dir * WALK_SPEED
	move_and_slide()
	if is_on_wall():
		move_dir *= -1.0
		velocity.x = move_dir * WALK_SPEED
	_try_collect_from_slides()
	_cull_if_fallen()

func _try_collect_from_slides() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var body := col.get_collider()
		if body is CapPlayer:
			collect(body)

func _on_sensor_body(body: Node) -> void:
	if body is CapPlayer:
		collect(body)

func _cull_if_fallen() -> void:
	if global_position.y > 440.0:
		queue_free()

func collect(_player: Node) -> void:
	# Override in subclasses.
	pass
