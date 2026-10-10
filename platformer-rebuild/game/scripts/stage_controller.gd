extends Node2D

const TILE := 16
const FxScript := preload("res://scripts/fx.gd")
const Catalog := preload("res://scripts/level_catalog.gd")
const Templates := preload("res://scripts/stage_templates.gd")

@export var level_id: String = "1-1"

@onready var world: Node2D = $World
@onready var entities: Node2D = $Entities

var player: CapPlayer
var _cleared: bool = false
var _active_world_item: Node = null

func _ready() -> void:
	level_id = "%d-%d" % [RunState.world, RunState.stage]
	_build_level()
	Music.play_theme(_music_theme())
	# Always restart at the beginning of the stage (not death position).
	# Pipe return from bonus rooms is the only mid-stage spawn exception.
	var spawn := Vector2(64, 304)
	if RunState.use_pipe_spawn and RunState.pipe_return_pos != Vector2.ZERO:
		spawn = Vector2(RunState.pipe_return_pos.x, mini(RunState.pipe_return_pos.y, 304.0))
		RunState.use_pipe_spawn = false
	RunState.clear_checkpoint()
	player = _spawn_player(spawn)
	player.died.connect(_on_player_died)
	var camera := $Camera2D
	camera._target = player
	RunState.max_camera_x = maxf(320.0, spawn.x)
	_spawn_hud()
	add_child(preload("res://scenes/pause_layer.tscn").instantiate())

func _process(delta: float) -> void:
	if _cleared:
		return
	RunState.tick_time(delta)
	Music.set_hurry(RunState.time_left > 0.0 and RunState.time_left <= SmbTuning.TIMER_HURRY_BELOW)
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
	var w := RunState.world
	var st := RunState.stage
	level_id = "%d-%d" % [w, st]
	Catalog.apply_sky(w, st)
	_add_parallax(_music_theme())
	Templates.build(self, w, st)
	if RunState.hard_quest:
		_apply_hard_quest()

func _build_ground(width_tiles: int, pit_ranges: Array = []) -> void:
	var pits := _shrink_pits(pit_ranges)
	for x in range(0, width_tiles):
		var in_pit := false
		for r in pits:
			if x >= r[0] and x <= r[1]:
				in_pit = true
				break
		if in_pit:
			continue
		_add_solid(Vector2(x * TILE, 320), Color("5a3d2b"))
		_add_solid(Vector2(x * TILE, 336), Color("3e2723"))

func _shrink_pits(pit_ranges: Array) -> Array:
	# Shorten every gap by 20% (keep start tile, shrink length).
	var out: Array = []
	for r in pit_ranges:
		var a: int = int(r[0])
		var b: int = int(r[1])
		var span: int = maxi(1, b - a + 1)
		var new_span: int = maxi(1, int(round(float(span) * 0.8)))
		out.append([a, a + new_span - 1])
	return out

func _build_level_1_1() -> void:
	_build_ground(112, [[18, 20], [46, 48], [72, 74]])
	_add_question(Vector2(10 * TILE, 240), QuestionBlock.Contents.COIN)
	_add_question(Vector2(11 * TILE, 240), QuestionBlock.Contents.BIG_BERRY)
	_add_question(Vector2(12 * TILE, 240), QuestionBlock.Contents.MULTI_COIN)
	_add_brick(Vector2(13 * TILE, 240))
	_add_brick(Vector2(14 * TILE, 240))
	_add_question(Vector2(15 * TILE, 240), QuestionBlock.Contents.ONE_UP)
	_add_hidden(Vector2(16 * TILE, 208), HiddenBlock.Contents.COIN)
	_add_hidden(Vector2(17 * TILE, 208), HiddenBlock.Contents.ONE_UP)
	_add_pipe(Vector2(28 * TILE, 288), true)
	_add_pipe(Vector2(58 * TILE, 288), false)
	_spawn_plant(Vector2(58 * TILE + 16, 288))
	for i in range(6):
		for j in range(i + 1):
			_add_solid(Vector2((96 + i) * TILE, 320 - (j + 1) * TILE), Color("6d4c41"))
	_spawn_browncap(Vector2(14 * TILE, 300))
	_spawn_browncap(Vector2(34 * TILE, 300))
	_spawn_shellbug(Vector2(40 * TILE, 300))
	_spawn_cliffbug(Vector2(48 * TILE, 300))
	_spawn_browncap(Vector2(64 * TILE, 300))
	_spawn_shellbug(Vector2(82 * TILE, 300))
	_spawn_goal(Vector2(104 * TILE, 320))
	# Secret warp near end stairs
	_add_warp(Vector2(92 * TILE, 272), 2, 1)

func _build_level_1_2() -> void:
	# Longer underground: darker ground, more Coilbugs, Blaze Bud block
	_build_ground(128, [[22, 24], [48, 50], [78, 80], [100, 102]])
	for x in range(0, 128):
		_add_solid(Vector2(x * TILE, 0), Color("1b263b")) # ceiling strip vibe
	_add_question(Vector2(8 * TILE, 240), QuestionBlock.Contents.BIG_BERRY)
	_add_question(Vector2(9 * TILE, 240), QuestionBlock.Contents.EMBER_BLOOM)
	_add_question(Vector2(10 * TILE, 240), QuestionBlock.Contents.COIN)
	_add_question(Vector2(36 * TILE, 224), QuestionBlock.Contents.EMBER_BLOOM)
	_add_pipe(Vector2(16 * TILE, 288), false)
	_spawn_plant(Vector2(16 * TILE + 16, 288))
	_spawn_hoverbug(Vector2(44 * TILE, 220))
	_spawn_cliffbug(Vector2(66 * TILE, 300))
	_spawn_ashbug(Vector2(90 * TILE, 300))
	for i in range(7):
		for j in range(i + 1):
			_add_solid(Vector2((108 + i) * TILE, 320 - (j + 1) * TILE), Color("415a77"))
	_spawn_browncap(Vector2(12 * TILE, 300))
	_spawn_shellbug(Vector2(20 * TILE, 300))
	_spawn_shellbug(Vector2(32 * TILE, 300))
	_spawn_browncap(Vector2(42 * TILE, 300))
	_spawn_shellbug(Vector2(58 * TILE, 300))
	_spawn_shellbug(Vector2(96 * TILE, 300))
	_spawn_goal(Vector2(120 * TILE, 320))

func _build_level_1_3() -> void:
	# Athletic: longer float course, Zap Star, springs, movers
	_build_ground(140, [[16, 19], [30, 33], [50, 53], [68, 71], [90, 93], [110, 113]])
	_add_question(Vector2(8 * TILE, 224), QuestionBlock.Contents.BIG_BERRY)
	_add_question(Vector2(20 * TILE, 208), QuestionBlock.Contents.SPARK_STAR)
	_add_question(Vector2(40 * TILE, 224), QuestionBlock.Contents.EMBER_BLOOM)
	_add_question(Vector2(84 * TILE, 192), QuestionBlock.Contents.MULTI_COIN)
	_add_hidden(Vector2(41 * TILE, 176), HiddenBlock.Contents.COIN)
	for x in range(24, 28):
		_add_brick(Vector2(x * TILE, 240))
	for x in range(44, 48):
		_add_brick(Vector2(x * TILE, 208))
	for x in range(17, 20):
		_add_solid(Vector2(x * TILE, 272), Color("e8a838"))
	_add_spring(Vector2(18 * TILE, 256))
	_add_spring(Vector2(100 * TILE, 256))
	_add_mover(Vector2(32 * TILE, 240), Vector2(80, 0), 2.8)
	_add_mover(Vector2(52 * TILE, 200), Vector2(0, 48), 2.2)
	_add_mover(Vector2(74 * TILE, 220), Vector2(64, -32), 2.5)
	for i in range(5):
		for j in range(i + 1):
			_add_solid(Vector2((124 + i) * TILE, 320 - (j + 1) * TILE), Color("6d4c41"))
	_spawn_browncap(Vector2(10 * TILE, 300))
	_spawn_shellbug(Vector2(26 * TILE, 300), true)
	_spawn_hoverbug(Vector2(48 * TILE, 180))
	_spawn_browncap(Vector2(38 * TILE, 300))
	_spawn_shellbug(Vector2(56 * TILE, 300))
	_spawn_cloud(Vector2(96 * TILE, 110))
	_spawn_goal(Vector2(134 * TILE, 320))

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
	_spawn_shellbug(Vector2(200, 300))
	_spawn_shellbug(Vector2(360, 300))
func _clear_world() -> void:
	for c in world.get_children():
		c.queue_free()
	for c in entities.get_children():
		c.queue_free()

func _music_theme() -> String:
	return Catalog.music_theme(RunState.world, RunState.stage)

func _add_parallax(theme: String) -> void:
	var bg := ParallaxBackground.new()
	bg.scroll_ignore_camera_zoom = true
	var layers: Array = []
	match theme:
		"water":
			layers = [["para_wave", 0.15], ["para_cloud", 0.25]]
		"castle":
			layers = [["para_castle", 0.12], ["para_smoke", 0.22]]
		"under":
			layers = [["para_under", 0.1], ["para_under2", 0.18]]
		_:
			layers = [["para_hill_far", 0.12], ["para_hill_near", 0.22], ["para_cloud", 0.08]]
	for entry in layers:
		var key: String = entry[0]
		var scale_x: float = entry[1]
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(scale_x, 0.0)
		var row := Node2D.new()
		var tex_w := int(Art.texture(key).get_size().x)
		if tex_w < 1:
			tex_w = 64
		if key.contains("hill"):
			row.position.y = 268.0
		elif key.contains("cloud") or key.contains("wave"):
			row.position.y = 48.0
		elif key.contains("castle") or key.contains("under"):
			row.position.y = 120.0
		for x in range(-64, 1400, tex_w):
			var s := Art.make_sprite(key, false)
			s.position.x = x
			row.add_child(s)
		layer.add_child(row)
		bg.add_child(layer)
	world.add_child(bg)

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
	var key := Art.tile_key_for_color(color)
	var vis := Art.make_sprite(key, false)
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
		QuestionBlock.Contents.COIN, QuestionBlock.Contents.MULTI_COIN:
			RunState.add_coin()
			_spawn_coin_burst(spawn_pos)
		QuestionBlock.Contents.BIG_BERRY:
			# Wiki: if already tall/fire, mushroom block yields flower instead.
			if RunState.form == "tall" or RunState.form == "fire":
				_spawn_world_item(_make_ember(spawn_pos))
			else:
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
	berry.position = pos
	return berry

func _make_ember(pos: Vector2) -> EmberBloom:
	var bloom := EmberBloom.new()
	bloom.position = pos
	return bloom

func _make_spark(pos: Vector2) -> SparkStar:
	var star := SparkStar.new()
	star.position = pos
	return star

func _make_one_up(pos: Vector2) -> OneUpBerry:
	var berry := OneUpBerry.new()
	berry.position = pos
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
	body.add_child(Art.make_sprite(Art.tile_key_for_color(color), false))
	world.add_child(body)
	return body

func _spawn_coin_burst(pos: Vector2) -> void:
	FxScript.coin_pop(entities, pos + Vector2(8, -8))

func _spawn_browncap(pos: Vector2) -> void:
	# Hard Quest swaps walkers for fireproof Ashbugs (wiki Buzzy Beetle role).
	if RunState.hard_quest:
		_spawn_shellbug(pos, false, false, true, false)
		return
	var e := Browncap.new()
	e.collision_layer = 4
	e.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 14)
	shape.shape = rect
	shape.position = Vector2(0, -7)
	e.add_child(shape)
	# Keep feet on / just above ground top (y=320).
	e.position = Vector2(pos.x, mini(pos.y, 304.0))
	entities.add_child(e)

func _spawn_shellbug(pos: Vector2, winged: bool = false, cliff_turn: bool = false, fireproof: bool = false, hover: bool = false) -> void:
	var e := Shellbug.new()
	e.winged = winged or hover
	e.cliff_turn = cliff_turn
	e.fireproof = fireproof
	if hover:
		e.flight = Shellbug.Flight.VERTICAL
	elif winged:
		e.flight = Shellbug.Flight.HOP
	e.collision_layer = 4
	e.collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 12)
	shape.shape = rect
	shape.position = Vector2(0, -6)
	e.add_child(shape)
	e.position = Vector2(pos.x, mini(pos.y, 304.0) if not hover else pos.y)
	entities.add_child(e)

func _spawn_cliffbug(pos: Vector2) -> void:
	_spawn_shellbug(pos, false, true, false, false)

func _spawn_ashbug(pos: Vector2) -> void:
	_spawn_shellbug(pos, false, false, true, false)

func _spawn_hoverbug(pos: Vector2) -> void:
	_spawn_shellbug(pos, true, false, false, true)

func _spawn_needler(pos: Vector2) -> void:
	var e := Needler.new()
	e.collision_layer = 4
	e.collision_mask = 1
	e.position = Vector2(pos.x, mini(pos.y, 304.0))
	entities.add_child(e)

func _spawn_iron_snout(pos: Vector2, shot_dir: float = -1.0) -> void:
	var c := IronSnout.new()
	c.position = pos
	c.shot_dir = shot_dir
	entities.add_child(c)

func _spawn_swimfin(pos: Vector2) -> void:
	var e := Swimfin.new()
	e.position = pos
	entities.add_child(e)

func _spawn_inkjet(pos: Vector2) -> void:
	var e := Inkjet.new()
	e.position = pos
	entities.add_child(e)

func _spawn_ember_blob(pos: Vector2) -> void:
	var e := EmberBlob.new()
	e.position = pos
	entities.add_child(e)

func _spawn_toss_twin(pos: Vector2) -> void:
	var e := TossTwin.new()
	e.collision_layer = 4
	e.collision_mask = 1
	e.position = Vector2(pos.x, mini(pos.y, 304.0))
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
	RunState.on_world_castle_cleared()
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
