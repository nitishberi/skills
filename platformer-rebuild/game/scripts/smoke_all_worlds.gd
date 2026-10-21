extends SceneTree

func _initialize() -> void:
	for w in range(1, 9):
		RunState.world = w
		RunState.stage = 1
		RunState.form = "small"
		RunState.reset_stage_timer()
		change_scene_to_file("res://scenes/level_play.tscn")
		await create_timer(0.12).timeout
		print("OK W%d-1" % w)
	quit()
