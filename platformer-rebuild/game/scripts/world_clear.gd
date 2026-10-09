extends Control

@onready var label: Label = $Center/Label

func _ready() -> void:
	get_tree().paused = false
	var cleared_world := RunState.world
	if cleared_world <= 1:
		# Finished castle while still on world 1 numbering before advance
		cleared_world = 1
	# After 1-4 axe we did not advance_stage; stay on world 1 stage 4 conceptually
	if RunState.world == 1:
		label.text = "WORLD 1 CLEAR\n\nDuke Spikes tumbles.\n\nEnter: World 2\nH: Hard Quest (faster foes)\nT: Title"
	else:
		label.text = "WORLD 2 CLEAR\n\nPipe Hop complete.\n\nH: Hard Quest replay\nT: Title"
		RunState.world_cleared_once = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				if RunState.world == 1:
					RunState.world = 2
					RunState.stage = 1
					RunState.form = "small"
					RunState.reset_stage_timer()
					get_tree().change_scene_to_file("res://scenes/life_fanfare.tscn")
				else:
					get_tree().change_scene_to_file("res://scenes/title.tscn")
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
