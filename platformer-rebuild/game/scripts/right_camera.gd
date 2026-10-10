extends Camera2D

@export var target_path: NodePath
var _target: Node2D
var _shake: float = 0.0

func _ready() -> void:
	add_to_group("game_camera")
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path) as Node2D
	make_current()
	limit_top = 0
	limit_bottom = 360
	limit_left = 0
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0

func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

func _process(delta: float) -> void:
	if _target == null:
		return
	var tx := _target.global_position.x
	RunState.max_camera_x = maxf(RunState.max_camera_x, tx)
	var base := Vector2(maxf(320.0, RunState.max_camera_x), 180.0)
	if _shake > 0.0:
		base += Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
		_shake = move_toward(_shake, 0.0, delta * 20.0)
	global_position = base
	limit_left = int(maxf(0.0, global_position.x - 320.0))
