extends Area2D
class_name GoalFlag

signal cleared

var done: bool = false
var _cloth: Sprite2D
var _pole_top_y: float
var _pole_bottom_y: float

func _ready() -> void:
	add_to_group("goal")
	body_entered.connect(_on_body)
	add_child(Art.make_sprite("flag_pole", true))
	_cloth = Art.make_sprite("flag_cloth", false)
	_cloth.position = Vector2(4, -56)
	add_child(_cloth)
	_pole_top_y = global_position.y - 64.0
	_pole_bottom_y = global_position.y

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		activate(body)

func activate(player: Node = null) -> void:
	if done:
		return
	done = true
	var cap := player as CapPlayer
	var touch_y := cap.global_position.y if cap else global_position.y - 32.0
	var bonus := SmbTuning.flagpole_bonus(touch_y, _pole_top_y, _pole_bottom_y)
	RunState.add_score(bonus + 1000)
	if cap:
		cap.input_locked = true
		cap.velocity = Vector2.ZERO
		var tw := create_tween()
		tw.tween_property(_cloth, "position:y", -48.0, 0.35)
		await cap.slide_down_pole(_pole_bottom_y - 4.0, 0.55)
	cleared.emit()
