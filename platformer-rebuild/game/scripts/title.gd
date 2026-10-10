extends Control

@onready var sub: Label = $Center/VBox/Sub

func _ready() -> void:
	get_tree().paused = false
	RunState.hard_quest = false
	RunState.reset_run()
	RenderingServer.set_default_clear_color(Color("7ec8e3"))
	Music.play_theme("title")
	_add_hills()
	# Force visible build stamp (do not rely only on .tscn text)
	sub.text = "8 WORLDS  ·  BUILD 0.3.0\nClassic moves. Original names and look.\nPress Enter or Space"
	var tw := create_tween().set_loops()
	tw.tween_property(sub, "modulate:a", 0.35, 0.55)
	tw.tween_property(sub, "modulate:a", 1.0, 0.55)

func _add_hills() -> void:
	var layer := ParallaxBackground.new()
	layer.scroll_ignore_camera_zoom = true
	for entry in [["para_hill_far", 0.05], ["para_hill_near", 0.08]]:
		var pl := ParallaxLayer.new()
		pl.motion_scale = Vector2(entry[1], 0.0)
		var row := Node2D.new()
		row.position.y = 280
		for x in range(-32, 720, 96):
			var s := Art.make_sprite(entry[0], false)
			s.position.x = x
			row.add_child(s)
		pl.add_child(row)
		layer.add_child(pl)
	add_child(layer)
	move_child(layer, 0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start") or event.is_action_pressed("jump"):
		Music.stop()
		get_tree().change_scene_to_file("res://scenes/life_fanfare.tscn")
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
		if RunState.world_cleared_once:
			RunState.hard_quest = true
			RunState.reset_run()
			RunState.hard_quest = true
			Music.stop()
			get_tree().change_scene_to_file("res://scenes/life_fanfare.tscn")
