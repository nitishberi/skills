extends Area2D
class_name GoalFlag

signal cleared

var done: bool = false
var _cloth: Sprite2D

func _ready() -> void:
	add_to_group("goal")
	body_entered.connect(_on_body)
	add_child(Art.make_sprite("flag_pole", true))
	_cloth = Art.make_sprite("flag_cloth", false)
	_cloth.position = Vector2(4, -56)
	add_child(_cloth)

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		activate()

func activate() -> void:
	if done:
		return
	done = true
	RunState.add_score(1000 + int(RunState.time_left) * 10)
	var tw := create_tween()
	tw.tween_property(_cloth, "position:y", -48.0, 0.6).set_trans(Tween.TRANS_BOUNCE)
	cleared.emit()
