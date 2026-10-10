extends Area2D
class_name WarpZone

@export var to_world: int = 2
@export var to_stage: int = 1

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 32)
	shape.shape = rect
	shape.position = Vector2(24, -16)
	add_child(shape)
	var label := Label.new()
	label.text = "WARP → W%d-%d" % [to_world, to_stage]
	label.position = Vector2(0, -40)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("f4d35e"))
	add_child(label)

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		RunState.world = to_world
		RunState.stage = to_stage
		RunState.reset_stage_timer()
		Sfx.play("clear")
		get_tree().change_scene_to_file("res://scenes/life_fanfare.tscn")
