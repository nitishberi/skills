extends Area2D
class_name SparkStar

var collected: bool = false

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	var s := Art.make_sprite("star", true)
	add_child(s)
	var tw := create_tween().set_loops()
	tw.tween_property(s, "scale", Vector2(1.15, 1.15), 0.35)
	tw.tween_property(s, "scale", Vector2(1.0, 1.0), 0.35)

func _on_body_entered(body: Node) -> void:
	if body is CapPlayer:
		collect(body)

func collect(player: Node) -> void:
	if collected:
		return
	collected = true
	if player.has_method("grant_invuln"):
		player.grant_invuln(6.0)
	queue_free()
