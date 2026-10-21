extends StaticBody2D
class_name QuestionBlock

signal bumped(block: QuestionBlock)

enum Contents { COIN, BIG_BERRY, EMBER_BLOOM, SPARK_STAR, ONE_UP, MULTI_COIN, EMPTY }

@export var contents: Contents = Contents.COIN
@export var multi_coins: int = 10 ## Coin Crate: wiki multi-coin block

var used: bool = false
var _multi_left: int = 0
var _multi_window: float = 0.0
var _sprite: Sprite2D

func _ready() -> void:
	add_to_group("question_blocks")
	collision_layer = 1
	collision_mask = 0
	_multi_left = multi_coins if contents == Contents.MULTI_COIN else 0
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

func _process(delta: float) -> void:
	if contents == Contents.MULTI_COIN and _multi_window > 0.0 and not used:
		_multi_window -= delta
		if _multi_window <= 0.0 and _multi_left > 0:
			# Window closed: remaining coins forfeit, block empties.
			_multi_left = 0
			used = true
			_sprite.texture = Art.texture("question_used")

func bump_from_below() -> void:
	if used:
		return
	if contents == Contents.MULTI_COIN:
		if _multi_left <= 0:
			used = true
			_sprite.texture = Art.texture("question_used")
			return
		_multi_left -= 1
		_multi_window = 0.55
		var tween_m := create_tween()
		tween_m.tween_property(self, "position:y", position.y - 4, 0.05)
		tween_m.tween_property(self, "position:y", position.y, 0.05)
		bumped.emit(self)
		if _multi_left <= 0:
			used = true
			_sprite.texture = Art.texture("question_used")
		return
	used = true
	_sprite.texture = Art.texture("question_used")
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 4, 0.05)
	tween.tween_property(self, "position:y", position.y, 0.05)
	bumped.emit(self)
