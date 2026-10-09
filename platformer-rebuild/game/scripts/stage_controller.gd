extends Node2D

const TILE := 16

@export var level_id: String = "1-1"

@onready var world: Node2D = $World
@onready var entities: Node2D = $Entities

var player: CapPlayer
var _cleared: bool = false
var _active_world_item: Node = null

func _ready() -> void:
	_build_level()
	var spawn := Vector2(48, 280)
	if RunState.use_pipe_spawn and RunState.pipe_return_pos != Vector2.ZERO:
		spawn = RunState.pipe_return_pos
		RunState.use_pipe_spawn = false
	player = _spawn_player(spawn)
	player.died.connect(_on_player_died)
	var camera := $Camera2D
	camera._target = player
	if spawn.x > 48:
		RunState.max_camera_x = spawn.x
	_spawn_hud()
	add_child(preload("res://scenes/pause_layer.tscn").instantiate())

func _process(delta: float) -> void:
	if _cleared:
		return
	RunState.tick_time(delta)
	if RunState.time_left <= 0.0:
		_on_player_died()

func _spawn_hud() -> void:
	add_child(preload("res://scenes/hud.tscn").instantiate())

func _spawn_player(pos: Vector2) -> CapPlayer:
	var p := CapPlayer.new()
	p.name = "Cap"
	p.collision_layer = 2
	p.collision_mask = 1 | 4 | 8 | 16 | 32
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 16)
	shape.shape = rect
	shape.position = Vector2(0, -8)
	p.add_child(shape)
	p.position = pos
	entities.add_child(p)
	return p

func _build_level() -> void:
	_clear_world()
	match level_id:
		"1-2":
			_build_level_1_2()
		"1-3":
			_build_level_1_3()
		"1-4":
			_build_level_1_4()
		"2-1":
			_build_level_2_1()
		"2-2":
			_build_level_2_2()
		"2-3":
			_build_level_2_3()
		"2-4":
			_build_level_2_4()
		_:
			_build_level_1_1()
	if RunState.hard_quest:
		_apply_hard_quest()

func _build_ground(width_tiles: int, pit_ranges: Array = []) -> void:
	for x in range(0, width_tiles):
		var in_pit := false
		for r in pit_ranges:
			if x >= r[0] and x <= r[1]:
				in_pit = true
				break
		if in_pit:
			continue
		_add_solid(Vector2(x * TILE, 320), Color("5a3d2b"))
		_add_solid(Vector2(x * TILE, 336), Color("3e2723"))

func _build_level_1_1() -> void:
	_build_ground(80, [[18, 21]])
	_add_question(Vector2(10 * TILE, 240), QuestionBlock.Contents.COIN)
	_add_question(Vector2(11 * TILE, 240), QuestionBlock.Contents.BIG_BERRY)
	_add_question(Vector2(12 * TILE, 240), QuestionBlock.Contents.COIN)
	_add_brick(Vector2(13 * TILE, 240))
	_add_brick(Vector2(14 * TILE, 240))
	_add_question(Vector2(15 * TILE, 240), QuestionBlock.Contents.ONE_UP)
	_add_hidden(Vector2(16 * TILE, 208), HiddenBlock.Contents.COIN)
	_add_hidden(Vector2(17 * TILE, 208), HiddenBlock.Contents.ONE_UP)
	_add_pipe(Vector2(28 * TILE, 288), true)
	for i in range(5):
		for j in range(i + 1):
			_add_solid(Vector2((55 + i) * TILE, 320 - (j + 1) * TILE), Color("6d4c41"))
	_spawn_browncap(Vector2(14 * TILE, 300))
	_spawn_browncap(Vector2(34 * TILE, 300))
	_spawn_shellbug(Vector2(40 * TILE, 300))
	_spawn_goal(Vector2(70 * TILE, 320))
	# Secret warp near end stairs
	_add_warp(Vector2(60 * TILE, 272), 2, 1)

func _build_level_1_2() -> void:
	# Slightly longer underground-ish: darker ground, more Shellbugs, Ember Bloom block
	_build_ground(96, [[22, 24], [48, 50]])
	for x in range(0, 96):
		_add_solid(Vector2(x * TILE, 0), Color("1b263b")) # ceiling strip vibe
	_add_question(Vector2(8 * TILE, 240), QuestionBlock.Contents.BIG_BERRY)
	_add_question(Vector2(9 * TILE, 240), QuestionBlock.Contents.EMBER_BLOOM)
	_add_question(Vector2(10 * TILE, 240), QuestionBlock.Contents.COIN)
	_add_question(Vector2(36 * TILE, 224), QuestionBlock.Contents.EMBER_BLOOM)
	_add_pipe(Vector2(16 * TILE, 288), false)
	_spawn_plant(Vector2(16 * TILE + 16, 288))
	for i in range(6):
		for j in range(i + 1):
			_add_solid(Vector2((70 + i) * TILE, 320 - (j + 1) * TILE), Color("415a77"))
	_spawn_browncap(Vector2(12 * TILE, 300))
	_spawn_shellbug(Vector2(20 * TILE, 300))
	_spawn_shellbug(Vector2(32 * TILE, 300))
	_spawn_browncap(Vector2(42 * TILE, 300))
	_spawn_shellbug(Vector2(58 * TILE, 300))
	_spawn_goal(Vector2(88 * TILE, 320))

func _build_level_1_3() -> void:
	# Athletic-ish: floating bricks, Spark Star, springs, movers
	_build_ground(100, [[16, 19], [30, 33], [50, 53], [68, 70]])
	_add_question(Vector2(8 * TILE, 224), QuestionBlock.Contents.BIG_BERRY)
	_add_question(Vector2(20 * TILE, 208), QuestionBlock.Contents.SPARK_STAR)
	_add_question(Vector2(40 * TILE, 224), QuestionBlock.Contents.EMBER_BLOOM)
	_add_hidden(Vector2(41 * TILE, 176), HiddenBlock.Contents.COIN)
	for x in range(24, 28):
		_add_brick(Vector2(x * TILE, 240))
	for x in range(44, 48):
		_add_brick(Vector2(x * TILE, 208))
	for x in range(17, 20):
		_add_solid(Vector2(x * TILE, 272), Color("e8a838"))
	_add_spring(Vector2(18 * TILE, 256))
	_add_mover(Vector2(32 * TILE, 240), Vector2(80, 0), 2.8)
	_add_mover(Vector2(52 * TILE, 200), Vector2(0, 48), 2.2)
	for i in range(4):
		for j in range(i + 1):
			_add_solid(Vector2((78 + i) * TILE, 320 - (j + 1) * TILE), Color("6d4c41"))
	_spawn_browncap(Vector2(10 * TILE, 300))
	_spawn_shellbug(Vector2(26 * TILE, 300), true)
	_spawn_browncap(Vector2(38 * TILE, 300))
	_spawn_shellbug(Vector2(56 * TILE, 300))
	_spawn_cloud(Vector2(60 * TILE, 120))
	_spawn_goal(Vector2(92 * TILE, 320))

func _build_level_1_4() -> void:
	# Castle: dark hall, lava pit, bridge, Duke Spikes, axe
	RenderingServer.set_default_clear_color(Color("1a1423"))
	_build_ground(40, [])
	# Hall ceiling
	for x in range(0, 70):
		_add_solid(Vector2(x * TILE, 0), Color("2c1e3a"))
		_add_solid(Vector2(x * TILE, 16), Color("2c1e3a"))
	# Mid platforms
	for x in range(8, 14):
		_add_solid(Vector2(x * TILE, 256), Color("4a235a"))
	_add_question(Vector2(10 * TILE, 200), QuestionBlock.Contents.EMBER_BLOOM)
	_add_question(Vector2(12 * TILE, 200), QuestionBlock.Contents.BIG_BERRY)
	for x in range(18, 22):
		_add_brick(Vector2(x * TILE, 240))
	# Lava pit under bridge area (tiles 40-55)
	var lava := LavaHazard.new()
	lava.configure(16, 2)
	lava.position = Vector2(40 * TILE, 320)
	entities.add_child(lava)
	# Bridge tiles over lava
	var bridge: Array = []
	for x in range(40, 54):
		var b := _add_solid_ref(Vector2(x * TILE, 288), Color("7f8c8d"))
		bridge.append(b)
	# Far bank
	for x in range(54, 70):
		_add_solid(Vector2(x * TILE, 320), Color("2c1e3a"))
		_add_solid(Vector2(x * TILE, 336), Color("1a1423"))
	_spawn_browncap(Vector2(15 * TILE, 300))
	_spawn_shellbug(Vector2(24 * TILE, 300))
	# Fire-bars in the hall
	_spawn_fire_bar(Vector2(20 * TILE + 8, 272), 5, 1.4)
	_spawn_fire_bar(Vector2(32 * TILE + 8, 256), 4, -1.8)
	# Duke on bridge
	var duke := _spawn_duke(Vector2(46 * TILE, 280), false)
	duke.set_meta("min_x", 41.0 * TILE)
	duke.set_meta("max_x", 52.0 * TILE)
	# Axe at end of bridge
	var axe := AxeGoal.new()
	axe.collision_layer = 32
	axe.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 20)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	axe.add_child(shape)
	axe.position = Vector2(53 * TILE + 8, 288)
	axe.monitoring = true
	axe.bind_bridge(bridge)
	axe.cleared.connect(_on_world_cleared)
	entities.add_child(axe)

func _build_level_2_1() -> void:
	# Underwater stage
	RenderingServer.set_default_clear_color(Color("1a5276"))
	_build_ground(90, [[20, 22], [40, 42]])
	var water := WaterZone.new()
	water.configure(Vector2(90 * TILE, 280))
	water.position = Vector2(0, 80)
	entities.add_child(water)
	_add_question(Vector2(8 * TILE, 200), QuestionBlock.Contents.BIG_BERRY)
	_add_question(Vector2(30 * TILE, 180), QuestionBlock.Contents.EMBER_BLOOM)
	_add_spring(Vector2(50 * TILE, 304))
	for x in range(60, 64):
		_add_brick(Vector2(x * TILE, 220))
	_spawn_shellbug(Vector2(18 * TILE, 300))
	_spawn_browncap(Vector2(35 * TILE, 300))
	_spawn_shellbug(Vector2(55 * TILE, 300))
	_spawn_goal(Vector2(82 * TILE, 320))

func _build_level_2_2() -> void:
	RenderingServer.set_default_clear_color(Color("7ec8e3"))
	_build_ground(100, [[15, 17], [35, 38], [55, 57]])
	_add_mover(Vector2(20 * TILE, 240), Vector2(96, 0), 3.0)
	_add_mover(Vector2(45 * TILE, 200), Vector2(0, 64), 2.4)
	_add_spring(Vector2(30 * TILE, 304))
	_add_question(Vector2(12 * TILE, 224), QuestionBlock.Contents.SPARK_STAR)
	_add_hidden(Vector2(13 * TILE, 192), HiddenBlock.Contents.ONE_UP)
	_add_pipe(Vector2(48 * TILE, 288), true)
	_spawn_plant(Vector2(48 * TILE + 16, 288))
	_spawn_cloud(Vector2(70 * TILE, 100))
	_spawn_browncap(Vector2(22 * TILE, 300))
	_spawn_shellbug(Vector2(40 * TILE, 300))
	_spawn_shellbug(Vector2(66 * TILE, 300))
	_spawn_goal(Vector2(92 * TILE, 320))

func _build_level_2_3() -> void:
	_build_ground(110, [[18, 21], [40, 43], [70, 73]])
	_add_question(Vector2(10 * TILE, 224), QuestionBlock.Contents.EMBER_BLOOM)
	_add_question(Vector2(50 * TILE, 208), QuestionBlock.Contents.BIG_BERRY)
	for x in range(28, 34):
		_add_brick(Vector2(x * TILE, 240))
	_add_spring(Vector2(44 * TILE, 304))
	_add_mover(Vector2(60 * TILE, 220), Vector2(72, -40), 2.6)
	_spawn_cloud(Vector2(36 * TILE, 90))
	_spawn_cloud(Vector2(80 * TILE, 110))
	_spawn_shellbug(Vector2(24 * TILE, 300), true)
	_spawn_browncap(Vector2(52 * TILE, 300))
	_spawn_shellbug(Vector2(78 * TILE, 300), true)
	_spawn_goal(Vector2(100 * TILE, 320))

func _build_level_2_4() -> void:
	RenderingServer.set_default_clear_color(Color("1a1423"))
	_build_ground(36, [])
	for x in range(0, 72):
		_add_solid(Vector2(x * TILE, 0), Color("2c1e3a"))
	_add_question(Vector2(8 * TILE, 200), QuestionBlock.Contents.EMBER_BLOOM)
	_spawn_fire_bar(Vector2(16 * TILE, 260), 5, 1.7)
	_spawn_fire_bar(Vector2(28 * TILE, 240), 6, -1.5)
	var lava := LavaHazard.new()
	lava.configure(18, 2)
	lava.position = Vector2(36 * TILE, 320)
	entities.add_child(lava)
	var bridge: Array = []
	for x in range(36, 52):
		bridge.append(_add_solid_ref(Vector2(x * TILE, 288), Color("7f8c8d")))
	for x in range(52, 72):
		_add_solid(Vector2(x * TILE, 320), Color("2c1e3a"))
	var duke := _spawn_duke(Vector2(42 * TILE, 280), true)
	duke.set_meta("min_x", 37.0 * TILE)
	duke.set_meta("max_x", 50.0 * TILE)
	var axe := AxeGoal.new()
	axe.collision_layer = 32
	axe.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 20)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	axe.add_child(shape)
	axe.position = Vector2(51 * TILE + 8, 288)
	axe.monitoring = true
	axe.bind_bridge(bridge)
	axe.cleared.connect(_on_world_cleared)
	entities.add_child(axe)

func _apply_hard_quest() -> void:
	# Swap some Browncaps for extra Shellbugs by spawning more
	_spawn_shellbug(Vector2(200, 300))
	_spawn_shellbug(Vector2(360, 300))

func _clear_world() -> void:
	for c in world.get_children():
		c.queue_free()
	for c in entities.get_children():
		c.queue_free()

func _add_solid(pos: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	shape.shape = rect
	shape.position = Vector2(TILE * 0.5, TILE * 0.5)
	body.add_child(shape)
	var vis := ColorRect.new()
	vis.size = Vector2(TILE - 1, TILE - 1)
	vis.position = Vector2(0.5, 0.5)
	vis.color = color
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(vis)
	world.add_child(body)

func _add_question(pos: Vector2, contents: QuestionBlock.Contents) -> void:
	var block := QuestionBlock.new()
	block.position = pos
	block.contents = contents
	block.bumped.connect(_on_question_bumped)
	world.add_child(block)

func _on_question_bumped(block: QuestionBlock) -> void:
	var spawn_pos := block.position + Vector2(8, -8)
	match block.contents:
		QuestionBlock.Contents.COIN:
			RunState.add_coin()
			_spawn_coin_burst(spawn_pos)
		QuestionBlock.Contents.BIG_BERRY:
			_spawn_world_item(_make_berry(spawn_pos))
		QuestionBlock.Contents.EMBER_BLOOM:
			_spawn_world_item(_make_ember(spawn_pos))
		QuestionBlock.Contents.SPARK_STAR:
			_spawn_world_item(_make_spark(spawn_pos))
		QuestionBlock.Contents.ONE_UP:
			_spawn_world_item(_make_one_up(spawn_pos))
		_:
			pass
	Sfx.play("bump")

func _on_hidden_bumped(block: HiddenBlock) -> void:
	var spawn_pos := block.position + Vector2(8, -8)
	match block.contents:
		HiddenBlock.Contents.COIN:
			RunState.add_coin()
			_spawn_coin_burst(spawn_pos)
		HiddenBlock.Contents.ONE_UP:
			_spawn_world_item(_make_one_up(spawn_pos))
		_:
			pass

func _spawn_world_item(item: Node) -> void:
	# One world item on screen at a time
	if _active_world_item and is_instance_valid(_active_world_item):
		_active_world_item.queue_free()
	_active_world_item = item
	entities.add_child(item)

func _make_berry(pos: Vector2) -> BigBerry:
	var berry := BigBerry.new()
	berry.collision_layer = 8
	berry.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 12)
	shape.shape = rect
	shape.position = Vector2(0, -6)
	berry.add_child(shape)
	berry.position = pos
	berry.monitoring = true
	return berry

func _make_ember(pos: Vector2) -> EmberBloom:
	var bloom := EmberBloom.new()
	bloom.collision_layer = 8
	bloom.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 14)
	shape.shape = rect
	shape.position = Vector2(0, -7)
	bloom.add_child(shape)
	bloom.position = pos
	bloom.monitoring = true
	return bloom

func _make_spark(pos: Vector2) -> SparkStar:
	var star := SparkStar.new()
	star.collision_layer = 8
	star.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 12)
	shape.shape = rect
	shape.position = Vector2(0, -6)
	star.add_child(shape)
	star.position = pos
	star.monitoring = true
	return star

func _make_one_up(pos: Vector2) -> OneUpBerry:
	var berry := OneUpBerry.new()
	berry.collision_layer = 8
	berry.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 12)
	shape.shape = rect
	shape.position = Vector2(0, -6)
	berry.add_child(shape)
	berry.position = pos
	berry.monitoring = true
	return berry

func _add_pipe(pos: Vector2, enterable: bool = true) -> void:
	_add_solid(pos, Color("2a9d8f"))
	_add_solid(pos + Vector2(TILE, 0), Color("2a9d8f"))
	_add_solid(pos + Vector2(0, TILE), Color("1f7a6a"))
	_add_solid(pos + Vector2(TILE, TILE), Color("1f7a6a"))
	if not enterable:
		return
	var mouth := PipeEntrance.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 10)
	shape.shape = rect
	shape.position = Vector2(0, -4)
	mouth.add_child(shape)
	mouth.position = pos + Vector2(TILE, 0)
	mouth.monitoring = true
	var tip := Label.new()
	tip.text = "↓ pipe"
	tip.position = Vector2(-10, -28)
	tip.add_theme_font_size_override("font_size", 10)
	tip.add_theme_color_override("font_color", Color("264653"))
	mouth.add_child(tip)
	entities.add_child(mouth)

func _add_hidden(pos: Vector2, contents: HiddenBlock.Contents) -> void:
	var block := HiddenBlock.new()
	block.position = pos
	block.contents = contents
	block.bumped.connect(_on_hidden_bumped)
	world.add_child(block)

func _add_spring(pos: Vector2) -> void:
	var s := SpringBoard.new()
	s.position = pos
	entities.add_child(s)

func _add_mover(pos: Vector2, travel: Vector2, period: float) -> void:
	var m := MovingPlatform.new()
	m.position = pos
	m.travel = travel
	m.period = period
	world.add_child(m)

func _add_warp(pos: Vector2, w: int, st: int) -> void:
	var z := WarpZone.new()
	z.position = pos
	z.to_world = w
	z.to_stage = st
	entities.add_child(z)

func _spawn_plant(pos: Vector2) -> void:
	var p := HazardPlant.new()
	p.position = pos
	entities.add_child(p)

func _spawn_cloud(pos: Vector2) -> void:
	var c := CloudDropper.new()
	c.position = pos
	entities.add_child(c)

func _spawn_fire_bar(pos: Vector2, arms: int = 4, speed: float = 1.6) -> void:
	var bar := FireBar.new()
	bar.position = pos
	bar.arm_count = arms
	bar.spin_speed = speed
	entities.add_child(bar)

func _add_brick(pos: Vector2) -> void:
	var brick := BreakableBrick.new()
	brick.position = pos
	world.add_child(brick)

func _add_solid_ref(pos: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	shape.shape = rect
	shape.position = Vector2(TILE * 0.5, TILE * 0.5)
	body.add_child(shape)
	var vis := ColorRect.new()
	vis.size = Vector2(TILE - 1, TILE - 1)
	vis.position = Vector2(0.5, 0.5)
	vis.color = color
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(vis)
	world.add_child(body)
	return body

func _spawn_coin_burst(pos: Vector2) -> void:
	# Visual only; coin already awarded in bump handler
	var c := ColorRect.new()
	c.size = Vector2(8, 10)
	c.position = pos + Vector2(-4, -10)
	c.color = Color("f1c40f")
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entities.add_child(c)
	var tween := create_tween()
	tween.tween_property(c, "position:y", c.position.y - 24, 0.2)
	tween.tween_callback(c.queue_free)

func _spawn_browncap(pos: Vector2) -> void:
	var e := Browncap.new()
	e.collision_layer = 4
	e.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 14)
	shape.shape = rect
	shape.position = Vector2(0, -7)
	e.add_child(shape)
	e.position = pos
	entities.add_child(e)

func _spawn_shellbug(pos: Vector2, winged: bool = false) -> void:
	var e := Shellbug.new()
	e.winged = winged
	e.collision_layer = 4
	e.collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 12)
	shape.shape = rect
	shape.position = Vector2(0, -6)
	e.add_child(shape)
	e.position = pos
	entities.add_child(e)

func _spawn_goal(pos: Vector2) -> void:
	var g := GoalFlag.new()
	g.collision_layer = 32
	g.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 64)
	shape.shape = rect
	shape.position = Vector2(0, -32)
	g.add_child(shape)
	g.position = pos
	g.monitoring = true
	g.cleared.connect(_on_cleared)
	entities.add_child(g)

func _spawn_duke(pos: Vector2, final_boss: bool = false) -> DukeSpikes:
	var d := DukeSpikes.new()
	d.is_final = final_boss
	d.collision_layer = 4
	d.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 28)
	shape.shape = rect
	shape.position = Vector2(0, -14)
	d.add_child(shape)
	d.position = pos
	entities.add_child(d)
	return d

func _on_cleared() -> void:
	if _cleared:
		return
	_cleared = true
	get_tree().paused = false
	Sfx.play("clear")
	RenderingServer.set_default_clear_color(Color("7ec8e3"))
	await get_tree().create_timer(0.5).timeout
	RunState.advance_stage()
	get_tree().change_scene_to_file("res://scenes/stage_clear.tscn")

func _on_world_cleared() -> void:
	if _cleared:
		return
	_cleared = true
	get_tree().paused = false
	Sfx.play("clear")
	RunState.last_clear_time_bonus = int(RunState.time_left) * 10
	RunState.add_score(RunState.last_clear_time_bonus + 5000)
	RunState.world_cleared_once = true
	RenderingServer.set_default_clear_color(Color("7ec8e3"))
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/world_clear.tscn")

func _on_player_died() -> void:
	if _cleared:
		return
	get_tree().paused = false
	RenderingServer.set_default_clear_color(Color("7ec8e3"))
	RunState.lose_life()
	if RunState.lives <= 0:
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/life_fanfare.tscn")
