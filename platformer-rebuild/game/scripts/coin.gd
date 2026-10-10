extends Area2D
class_name HopCoin

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body)
	var s := Art.make_sprite("coin", true)
	add_child(s)
	var tw := create_tween().set_loops()
	tw.tween_property(s, "position:y", -12.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(s, "position:y", -8.0, 0.4).set_trans(Tween.TRANS_SINE)

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		RunState.add_coin()
		queue_free()
