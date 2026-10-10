extends "res://scripts/glide_powerup.gd"
class_name BigBerry

func _ready() -> void:
	_powerup_ready("berry")

func collect(player: Node) -> void:
	if collected:
		return
	collected = true
	if player.has_method("grow"):
		player.grow()
	queue_free()
