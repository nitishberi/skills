extends Area2D
class_name SparkStar

var collected: bool = false
var _t: float = 0.0

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body)
	_build_visual()

func _build_visual() -> void:
	var core := ColorRect.new()
	core.name = "Core"
	core.size = Vector2(12, 12)
	core.position = Vector2(-6, -12)
	core.color = Color("f4d35e")
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(core)

func _process(delta: float) -> void:
	_t += delta
	modulate = Color(1, 1, 1, 0.65 + 0.35 * sin(_t * 10.0))

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		collect(body)

func collect(player: Node) -> void:
	if collected:
		return
	collected = true
	if player.has_method("grant_invuln"):
		player.grant_invuln(7.0)
	queue_free()
