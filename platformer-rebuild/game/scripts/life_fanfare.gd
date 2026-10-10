extends Control

@onready var label: Label = $Center/Label

func _ready() -> void:
	RunState.reset_time_only()
	# Keep form across lives within a run except death already resets form
	label.text = "WORLD %d-%d\n\nCAP x %d" % [RunState.world, RunState.stage, RunState.lives]
	await get_tree().create_timer(1.4).timeout
	get_tree().change_scene_to_file(RunState.scene_for_current_stage())
