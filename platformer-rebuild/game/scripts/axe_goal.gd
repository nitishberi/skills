extends Area2D
class_name AxeGoal

signal cleared

var done: bool = false
var bridge_nodes: Array = []

func _ready() -> void:
	add_to_group("goal")
	body_entered.connect(_on_body)
	add_child(Art.make_sprite("axe", true))

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
