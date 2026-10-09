extends Area2D
class_name HopCoin

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body)
	var v := ColorRect.new()
	v.size = Vector2(8, 10)
	v.position = Vector2(-4, -10)
	v.color = Color("f1c40f")
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		RunState.add_coin()
		queue_free()
