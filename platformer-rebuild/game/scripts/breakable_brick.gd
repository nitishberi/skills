extends StaticBody2D
class_name BreakableBrick

const FxScript := preload("res://scripts/fx.gd")

var _sprite: Sprite2D

func _ready() -> void:
	add_to_group("breakable_bricks")
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
	_sprite = Art.make_sprite("brick", false)
	add_child(_sprite)

func bump_from_below() -> void:
	if RunState.form == "small":
		var base := position.y
		var tween := create_tween()
		tween.tween_property(self, "position:y", base - 3, 0.04)
		tween.tween_property(self, "position:y", base, 0.04)
		return
	RunState.add_score(50)
	FxScript.brick_shards(get_tree().current_scene, global_position)
	queue_free()
