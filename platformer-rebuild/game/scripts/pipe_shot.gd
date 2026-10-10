extends Area2D
class_name PipeShot
## Straight fireproof projectile.

const SPEED := 140.0

var dir: float = -1.0
var life: float = 4.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("hazards")
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6
	shape.shape = circle
	add_child(shape)
	add_child(Art.make_sprite("pipe_shot", true))
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	position.x += dir * SPEED * delta
	life -= delta
	if life <= 0.0 or position.x < -40.0 or position.x > 3000.0:
		queue_free()

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		body._die()

func stomp() -> void:
	RunState.add_score(200)
	queue_free()

func hit_by_ember() -> void:
	# Fireproof.
	pass
