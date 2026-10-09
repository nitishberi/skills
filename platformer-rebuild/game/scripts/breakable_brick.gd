extends StaticBody2D
class_name BreakableBrick

var _vis: ColorRect

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
	_vis = ColorRect.new()
	_vis.size = Vector2(15, 15)
	_vis.position = Vector2(0.5, 0.5)
	_vis.color = Color("a67c52")
	_vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vis)

func bump_from_below() -> void:
	# Tall/fire Caps shatter; small Caps just nudge
	if RunState.form == "small":
		var base := position.y
		var tween := create_tween()
		tween.tween_property(self, "position:y", base - 3, 0.04)
		tween.tween_property(self, "position:y", base, 0.04)
		return
	RunState.add_score(50)
	queue_free()
