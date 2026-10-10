extends Control

@onready var label: Label = $Center/Label

func _ready() -> void:
	get_tree().paused = false
	var w := RunState.world
	if w >= RunState.MAX_WORLDS:
		label.text = "PIPE HOP COMPLETE\n\nYou cleared all eight worlds.\nDuke Spikes is done.\n\nH: Hard Quest\nT: Title"
	elif w == 1:
		label.text = "WORLD 1 CLEAR\n\nThat Duke was an impostor.\nThe real castle waits ahead.\n\nEnter: World 2\nH: Hard Quest\nT: Title"
	else:
		label.text = "WORLD %d CLEAR\n\nOnward, Cap.\n\nEnter: World %d\nH: Hard Quest\nT: Title" % [w, w + 1]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				if RunState.world >= RunState.MAX_WORLDS:
					get_tree().change_scene_to_file("res://scenes/title.tscn")
				else:
					RunState.advance_to_next_world()
					get_tree().change_scene_to_file("res://scenes/life_fanfare.tscn")
			KEY_H:
				RunState.hard_quest = true
				RunState.world = 1
				RunState.stage = 1
				RunState.form = "small"
				RunState.lives = RunState.START_LIVES
				RunState.reset_stage_timer()
				get_tree().change_scene_to_file("res://scenes/life_fanfare.tscn")
			KEY_T:
				RunState.hard_quest = false
				RunState.reset_run()
				get_tree().change_scene_to_file("res://scenes/title.tscn")
