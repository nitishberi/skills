extends StaticBody2D
class_name QuestionBlock

signal bumped(block: QuestionBlock)

enum Contents { COIN, BIG_BERRY, EMBER_BLOOM, SPARK_STAR, ONE_UP, EMPTY }

@export var contents: Contents = Contents.COIN

var used: bool = false
var _vis: ColorRect

func _ready() -> void:
	add_to_group("question_blocks")
	collision_layer = 1
	collision_mask = 0
	if not has_node("CollisionShape2D"):
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, 16)
		shape.shape = rect
		shape.position = Vector2(8, 8)
		add_child(shape)
	_vis = ColorRect.new()
	_vis.size = Vector2(15, 15)
	_vis.position = Vector2(0.5, 0.5)
	_vis.color = Color("e8a838")
	_vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vis)

func bump_from_below() -> void:
	if used:
		return
	used = true
	_vis.color = Color("7f8c8d")
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 4, 0.05)
	tween.tween_property(self, "position:y", position.y, 0.05)
	bumped.emit(self)
