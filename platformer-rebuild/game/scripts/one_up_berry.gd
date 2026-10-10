extends "res://scripts/glide_powerup.gd"
class_name OneUpBerry

func _ready() -> void:
	_powerup_ready("one_up")

func collect(_player: Node) -> void:
	if collected:
		return
	collected = true
	RunState.add_life()
	Sfx.play("power")
	queue_free()
