extends "res://scripts/glide_powerup.gd"
class_name EmberBloom

func _ready() -> void:
	_powerup_ready("ember")

func collect(player: Node) -> void:
	if collected:
		return
	collected = true
	if player.has_method("grant_fire"):
		player.grant_fire()
	queue_free()
