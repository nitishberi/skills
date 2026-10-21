extends Control

@onready var label: Label = $Center/Label

func _ready() -> void:
	get_tree().paused = false
	label.text = "GAME OVER\n\nSCORE %06d\n\nEnter: title\nC: continue world %d" % [
		RunState.score,
		RunState.continue_world,
	]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start") or event.is_action_pressed("jump"):
		RunState.hard_quest = false
		RunState.reset_run()
		get_tree().change_scene_to_file("res://scenes/title.tscn")
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C or event.physical_keycode == KEY_C:
			RunState.apply_continue()
			get_tree().change_scene_to_file("res://scenes/life_fanfare.tscn")
