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
	# Sky Rider stops pursuing at the flag (wiki Lakitu).
	for n in get_tree().get_nodes_in_group("sky_riders"):
		if n.has_method("stop_chase"):
			n.stop_chase()
	var cap := player as CapPlayer
	var touch_y := cap.global_position.y if cap else global_position.y - 32.0
	var bonus := SmbTuning.flagpole_bonus(touch_y, _pole_top_y, _pole_bottom_y)
	RunState.add_score(bonus + 1000)
	# Wiki fireworks: ones digit of timer is 1, 3, or 6 → that many fireworks × 500.
	var ones := int(floor(RunState.time_left)) % 10
	if ones == 1 or ones == 3 or ones == 6:
		for i in ones:
			RunState.add_score(500)
			_spawn_firework(i)
	if cap:
		cap.input_locked = true
		cap.velocity = Vector2.ZERO
		var tw := create_tween()
		tw.tween_property(_cloth, "position:y", -48.0, 0.35)
		await cap.slide_down_pole(_pole_bottom_y - 4.0, 0.55)
	cleared.emit()

func _spawn_firework(i: int) -> void:
	var fx := Sprite2D.new()
	fx.texture = Art.texture("firework")
	fx.centered = true
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.global_position = global_position + Vector2(-20.0 - i * 18.0, -80.0 - i * 10.0)
	get_tree().current_scene.add_child(fx)
	var tw := fx.create_tween()
	tw.tween_property(fx, "modulate:a", 0.0, 0.55)
	tw.tween_callback(fx.queue_free)
	Sfx.play("clear")
