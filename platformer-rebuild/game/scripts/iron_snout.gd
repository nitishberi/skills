extends Node2D
class_name IronSnout
## Cannon that fires Pipe Shots; silent if Cap is beside it.

@export var interval: float = 2.2
@export var shot_dir: float = -1.0

var _cd: float = 0.8

func _ready() -> void:
	add_child(Art.make_sprite("cannon", true))

func _player_near() -> bool:
	var p := get_tree().get_first_node_in_group("player")
	if p == null or not (p is Node2D):
		return false
	return absf((p as Node2D).global_position.x - global_position.x) < 28.0

func _process(delta: float) -> void:
	_cd -= delta
	if _cd > 0.0:
		return
	_cd = interval
	if _player_near():
		return
	var shot := PipeShot.new()
	shot.dir = shot_dir
	shot.global_position = global_position + Vector2(shot_dir * 12.0, -10.0)
	get_tree().current_scene.add_child(shot)
