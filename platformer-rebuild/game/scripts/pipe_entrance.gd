extends Area2D
class_name PipeEntrance

@export var bonus_scene: String = "res://scenes/bonus_room.tscn"
@export var return_marker: String = "pipe_a"

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body)
	body_exited.connect(_on_body_exit)
	set_meta("player_on", false)

func _on_body(body: Node) -> void:
	if body is CapPlayer:
		set_meta("player_on", true)
		set_meta("player", body)

func _on_body_exit(body: Node) -> void:
	if body is CapPlayer:
		set_meta("player_on", false)

func _physics_process(_delta: float) -> void:
	if not get_meta("player_on"):
		return
	if not Input.is_action_pressed("move_down"):
		return
	var player: CapPlayer = get_meta("player")
	if player == null or not is_instance_valid(player):
		return
	if not player.is_on_floor():
		return
	RunState.pipe_return_scene = get_tree().current_scene.scene_file_path
	if RunState.pipe_return_scene == "":
		RunState.pipe_return_scene = RunState.scene_for_current_stage()
	RunState.pipe_return_pos = player.global_position + Vector2(40, 0)
	RunState.pipe_marker = return_marker
	RunState.use_pipe_spawn = true
	get_tree().change_scene_to_file(bonus_scene)
