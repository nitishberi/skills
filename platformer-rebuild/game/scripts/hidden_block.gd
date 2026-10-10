extends StaticBody2D
class_name HiddenBlock

signal bumped(block: HiddenBlock)

enum Contents { COIN, ONE_UP, EMPTY }

@export var contents: Contents = Contents.COIN

var revealed: bool = false
var _sprite: Sprite2D

func _ready() -> void:
	add_to_group("hidden_blocks")
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
	_sprite = Art.make_sprite("hidden", false)
	_sprite.modulate.a = 0.0
	add_child(_sprite)

func bump_from_below() -> void:
	if not revealed:
		revealed = true
		_sprite.modulate.a = 1.0
		_sprite.texture = Art.texture("question")
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 4, 0.05)
	tween.tween_property(self, "position:y", position.y, 0.05)
	bumped.emit(self)
