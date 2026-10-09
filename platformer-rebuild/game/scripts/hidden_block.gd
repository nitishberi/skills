extends StaticBody2D
class_name HiddenBlock

signal bumped(block: HiddenBlock)

enum Contents { COIN, ONE_UP, EMPTY }

@export var contents: Contents = Contents.COIN

var used: bool = false
var revealed: bool = false
var _vis: ColorRect

func _ready() -> void:
	add_to_group("question_blocks")
	add_to_group("hidden_blocks")
	collision_layer = 1
	collision_mask = 0
	# Invisible until bumped, but still solid from below only via one-way feel:
	# Keep solid always so bump works; hide visual.
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
	_vis.modulate.a = 0.0
	_vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vis)

func bump_from_below() -> void:
	if used:
		return
	if not revealed:
		revealed = true
		_vis.modulate.a = 1.0
	used = true
	_vis.color = Color("7f8c8d")
	Sfx.play("bump")
	bumped.emit(self)
