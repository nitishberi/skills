extends Control

@onready var label: Label = $Center/Label

func _ready() -> void:
	get_tree().paused = false
	label.text = "STAGE CLEAR\n\nTIME BONUS %d\nSCORE %06d\n\nGet ready..." % [
		RunState.last_clear_time_bonus,
		RunState.score,
	]
	await get_tree().create_timer(1.8).timeout
	get_tree().change_scene_to_file("res://scenes/life_fanfare.tscn")
