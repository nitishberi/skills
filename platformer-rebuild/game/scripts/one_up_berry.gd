extends Area2D
class_name OneUpBerry

var collected: bool = false
var active: bool = false
var move_dir: float = 1.0

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body)
	_build_visual()
	var start_y := position.y
	var tween := create_tween()
	tween.tween_property(self, "position:y", start_y - 20, 0.25)
	tween.tween_callback(func(): active = true)

func _build_visual() -> void:
	var berry := ColorRect.new()
	berry.size = Vector2(12, 12)
	berry.position = Vector2(-6, -12)
	berry.color = Color("27ae60")
	berry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(berry)
	var dot := ColorRect.new()
	dot.size = Vector2(4, 4)
	dot.position = Vector2(-2, -9)
	dot.color = Color("d5f5e3")
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dot)

func _physics_process(delta: float) -> void:
	if collected or not active:
		return
	position.x += move_dir * 45.0 * delta

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		collect(body)

func collect(_player: Node) -> void:
	if collected:
		return
	collected = true
	RunState.lives += 1
	RunState.add_score(1000)
	RunState.changed.emit()
	queue_free()
