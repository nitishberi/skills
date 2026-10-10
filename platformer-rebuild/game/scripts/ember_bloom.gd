extends Area2D
class_name EmberBloom

var collected: bool = false
var move_dir: float = 1.0
var speed: float = 50.0
var active: bool = false

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	add_child(Art.make_sprite("ember", true))
	var start_y := position.y
	var tween := create_tween()
	tween.tween_property(self, "position:y", start_y - 20, 0.25)
	tween.tween_callback(func(): active = true)

func _physics_process(delta: float) -> void:
	if collected or not active:
		return
	position.x += move_dir * speed * delta
	if position.x < 0.0 or position.x > 2000.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is CapPlayer:
		collect(body)

func collect(player: Node) -> void:
	if collected:
		return
	collected = true
	if player.has_method("grant_fire"):
		player.grant_fire()
	queue_free()
