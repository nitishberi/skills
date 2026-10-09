extends Area2D
class_name BigBerry

var collected: bool = false
var move_dir: float = 1.0
var speed: float = 50.0
var active: bool = false

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	_build_visual()
	# Pop upward then drift (slice: no tile collision for pickups yet)
	var start_y := position.y
	var tween := create_tween()
	tween.tween_property(self, "position:y", start_y - 20, 0.25)
	tween.tween_callback(func(): active = true)

func _build_visual() -> void:
	var berry := ColorRect.new()
	berry.size = Vector2(12, 12)
	berry.position = Vector2(-6, -12)
	berry.color = Color("c0392b")
	berry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(berry)
	var stem := ColorRect.new()
	stem.size = Vector2(4, 4)
	stem.position = Vector2(-2, -15)
	stem.color = Color("27ae60")
	stem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stem)

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
	if player.has_method("grow"):
		player.grow()
	queue_free()
