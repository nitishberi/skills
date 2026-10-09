extends Area2D
class_name EmberBloom

var collected: bool = false

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body)
	_build_visual()

func _build_visual() -> void:
	var petal := ColorRect.new()
	petal.size = Vector2(14, 14)
	petal.position = Vector2(-7, -14)
	petal.color = Color("e76f51")
	petal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(petal)
	var center := ColorRect.new()
	center.size = Vector2(6, 6)
	center.position = Vector2(-3, -11)
	center.color = Color("f4d35e")
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		collect(body)

func collect(player: Node) -> void:
	if collected:
		return
	collected = true
	if player.has_method("grant_fire"):
		player.grant_fire()
	elif player.has_method("grow"):
		player.grow()
		if player.has_method("grant_fire"):
			player.grant_fire()
	queue_free()
