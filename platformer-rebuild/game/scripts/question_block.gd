extends StaticBody2D
class_name QuestionBlock

signal bumped(block: QuestionBlock)

enum Contents { COIN, BIG_BERRY, EMBER_BLOOM, SPARK_STAR, ONE_UP, EMPTY }

@export var contents: Contents = Contents.COIN

var used: bool = false
var _sprite: Sprite2D

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
	_sprite = Art.make_sprite("question", false)
	_sprite.position = Vector2(0, 0)
	add_child(_sprite)

func bump_from_below() -> void:
	if used:
		return
	used = true
	_sprite.texture = Art.texture("question_used")
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 4, 0.05)
	tween.tween_property(self, "position:y", position.y, 0.05)
	bumped.emit(self)
