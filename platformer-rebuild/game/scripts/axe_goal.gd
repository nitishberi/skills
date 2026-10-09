extends Area2D
class_name AxeGoal

signal cleared

var done: bool = false
var bridge_nodes: Array = []

func _ready() -> void:
	add_to_group("goal")
	body_entered.connect(_on_body)
	_build_visual()

func _build_visual() -> void:
	var axe := ColorRect.new()
	axe.size = Vector2(12, 16)
	axe.position = Vector2(-6, -16)
	axe.color = Color("bdc3c7")
	axe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(axe)
	var handle := ColorRect.new()
	handle.size = Vector2(4, 20)
	handle.position = Vector2(-2, -10)
	handle.color = Color("8e5a2b")
	handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(handle)

func bind_bridge(nodes: Array) -> void:
	bridge_nodes = nodes

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		activate()

func activate() -> void:
	if done:
		return
	done = true
	for n in bridge_nodes:
		if is_instance_valid(n):
			n.queue_free()
	var dukes := get_tree().get_nodes_in_group("duke_spikes")
	for d in dukes:
		if d.has_method("drop_into_lava"):
			d.drop_into_lava()
	RunState.add_score(2000 + int(RunState.time_left) * 10)
	cleared.emit()
