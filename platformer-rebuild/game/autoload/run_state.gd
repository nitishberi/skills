extends Node

signal changed

const START_LIVES := 3
const START_TIME := 300
const STAGES_PER_WORLD := 4

var lives: int = START_LIVES
var score: int = 0
var coins: int = 0
var world: int = 1
var stage: int = 1
var time_left: float = START_TIME
var form: String = "small"
var invuln_timer: float = 0.0
var max_camera_x: float = 0.0
var pipe_return_scene: String = ""
var pipe_return_pos: Vector2 = Vector2.ZERO
var pipe_marker: String = ""
var use_pipe_spawn: bool = false
var hard_quest: bool = false
var world_cleared_once: bool = false
var continue_world: int = 1
var last_clear_time_bonus: int = 0

func reset_run() -> void:
	lives = START_LIVES
	score = 0
	coins = 0
	world = 1
	stage = 1
	time_left = START_TIME
	form = "small"
	invuln_timer = 0.0
	max_camera_x = 0.0
	pipe_return_scene = ""
	use_pipe_spawn = false
	# hard_quest persists until title resets it intentionally
	changed.emit()

func reset_stage_timer() -> void:
	time_left = START_TIME
	max_camera_x = 0.0
	changed.emit()

func add_score(amount: int) -> void:
	score += amount
	changed.emit()

func add_coin() -> void:
	coins += 1
	add_score(200)
	Sfx.play("coin")
	if coins >= 100:
		coins = 0
		lives += 1
	changed.emit()

func add_life() -> void:
	lives += 1
	changed.emit()

func set_form(next: String) -> void:
	form = next
	changed.emit()

func lose_life() -> void:
	lives -= 1
	form = "small"
	invuln_timer = 0.0
	continue_world = world
	changed.emit()

func tick_time(delta: float) -> void:
	if time_left <= 0.0:
		return
	time_left = maxf(0.0, time_left - delta)
	changed.emit()

func world_stage_label() -> String:
	var tag := "H" if hard_quest else "W"
	return "%s%d-%d" % [tag, world, stage]

func scene_for_current_stage() -> String:
	var key := "%d-%d" % [world, stage]
	match key:
		"1-1":
			return "res://scenes/level_1_1.tscn"
		"1-2":
			return "res://scenes/level_1_2.tscn"
		"1-3":
			return "res://scenes/level_1_3.tscn"
		"1-4":
			return "res://scenes/level_1_4.tscn"
		"2-1":
			return "res://scenes/level_2_1.tscn"
		"2-2":
			return "res://scenes/level_2_2.tscn"
		"2-3":
			return "res://scenes/level_2_3.tscn"
		"2-4":
			return "res://scenes/level_2_4.tscn"
		_:
			return "res://scenes/level_1_1.tscn"

func advance_stage() -> void:
	last_clear_time_bonus = int(time_left) * 10
	add_score(last_clear_time_bonus)
	stage += 1
	if stage > STAGES_PER_WORLD:
		stage = 1
		world += 1
	changed.emit()

func apply_continue() -> void:
	lives = START_LIVES
	form = "small"
	world = maxi(1, continue_world)
	stage = 1
	reset_stage_timer()
	changed.emit()
