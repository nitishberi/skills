extends Control

func _ready() -> void:
	get_tree().paused = false
	RunState.hard_quest = false
	RunState.reset_run()
	RenderingServer.set_default_clear_color(Color("7ec8e3"))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start") or event.is_action_pressed("jump"):
		get_tree().change_scene_to_file("res://scenes/life_fanfare.tscn")
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
		if RunState.world_cleared_once:
			RunState.hard_quest = true
			RunState.reset_run()
			RunState.hard_quest = true
			get_tree().change_scene_to_file("res://scenes/life_fanfare.tscn")
