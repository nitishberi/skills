extends Node

signal changed

const START_LIVES := 3
const START_TIME := 400
const STAGES_PER_WORLD := 4
const MAX_WORLDS := 8

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
var checkpoint_pos: Vector2 = Vector2.ZERO
var has_checkpoint: bool = false

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
	clear_checkpoint()
	# hard_quest persists until title resets it intentionally
	changed.emit()

func reset_stage_timer() -> void:
	time_left = START_TIME
	max_camera_x = 0.0
	clear_checkpoint()
	changed.emit()

func reset_time_only() -> void:
	time_left = START_TIME
	changed.emit()

func set_checkpoint(pos: Vector2) -> void:
	checkpoint_pos = pos
	has_checkpoint = true

func clear_checkpoint() -> void:
	has_checkpoint = false
	checkpoint_pos = Vector2.ZERO

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
	# Death always restarts the stage from the beginning (no mid-level checkpoint).
	clear_checkpoint()
	max_camera_x = 0.0
	changed.emit()

func tick_time(delta: float) -> void:
	if time_left <= 0.0:
		return
	time_left = maxf(0.0, time_left - delta * SmbTuning.TIMER_UNITS_PER_SECOND)
	changed.emit()

func world_stage_label() -> String:
	var tag := "H" if hard_quest else "W"
	return "%s%d-%d" % [tag, world, stage]

func scene_for_current_stage() -> String:
	return "res://scenes/level_play.tscn"

func advance_stage() -> void:
	last_clear_time_bonus = int(time_left) * 10
	add_score(last_clear_time_bonus)
	stage += 1
	if stage > STAGES_PER_WORLD:
		stage = 1
		world += 1
	if world > MAX_WORLDS:
		world = MAX_WORLDS
		stage = STAGES_PER_WORLD
	changed.emit()

func on_world_castle_cleared() -> void:
	last_clear_time_bonus = int(time_left) * 10
	add_score(last_clear_time_bonus + 5000)
	world_cleared_once = true
	changed.emit()

func advance_to_next_world() -> void:
	if world >= MAX_WORLDS:
		return
	world += 1
	stage = 1
	reset_stage_timer()
	changed.emit()

func apply_continue() -> void:
	lives = START_LIVES
	form = "small"
	world = maxi(1, continue_world)
	stage = 1
	reset_stage_timer()
	changed.emit()
