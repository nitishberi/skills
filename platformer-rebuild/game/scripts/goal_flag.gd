extends Area2D
class_name GoalFlag

signal cleared

var done: bool = false

func _ready() -> void:
	add_to_group("goal")
	body_entered.connect(_on_body)
	_build_visual()

func _build_visual() -> void:
	var pole := ColorRect.new()
	pole.size = Vector2(4, 64)
	pole.position = Vector2(-2, -64)
	pole.color = Color("ecf0f1")
	pole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pole)
	var flag := ColorRect.new()
	flag.size = Vector2(20, 12)
	flag.position = Vector2(2, -60)
	flag.color = Color("e8a838")
	flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flag)

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		activate()

func activate() -> void:
	if done:
		return
	done = true
	RunState.add_score(1000 + int(RunState.time_left) * 10)
	cleared.emit()
