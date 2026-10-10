extends RefCounted
## Original Pipe Hop layouts: wiki stage types, bigger denser courses, teaching beats.
## No Nintendo map copies.

const Catalog := preload("res://scripts/level_catalog.gd")

static func build(sc: Node, world: int, stage: int) -> void:
	if Catalog.is_handcrafted(world, stage):
		_build_handcrafted(sc, world, stage)
	else:
		_build_paced(sc, world, stage)

static func _build_handcrafted(sc: Node, world: int, stage: int) -> void:
	if world == 2 and stage == 2:
		_build_water(sc, world, stage)
		return
	var key := "%d-%d" % [world, stage]
	match key:
		"1-1":
			sc.call("_build_level_1_1")
		"1-2":
			sc.call("_build_level_1_2")
		"1-3":
			sc.call("_build_level_1_3")
		"1-4":
			sc.call("_build_level_1_4")
		"2-1":
			sc.call("_build_level_2_1")
		"2-3":
			sc.call("_build_level_2_3")
		"2-4":
			sc.call("_build_level_2_4")
		_:
			_build_paced(sc, world, stage)

static func _build_paced(sc: Node, world: int, stage: int) -> void:
	match Catalog.stage_kind(world, stage):
		"castle":
			_build_castle(sc, world, stage)
		"athletic":
			_build_athletic(sc, world, stage)
		"water":
			_build_water(sc, world, stage)
		"under":
			_build_under(sc, world, stage)
		_:
			_build_ground(sc, world, stage)

static func _build_ground(sc: Node, world: int, stage: int) -> void:
	var w := Catalog.level_width_tiles(world, stage)
	var pits := _pits(world, stage, w)
	sc.call("_build_ground", w, pits)
	# Segment A: teach grow + coins + first pit
	sc.call("_add_question", Vector2(8 * 16, 240), QuestionBlock.Contents.BIG_BERRY)
	sc.call("_add_question", Vector2(10 * 16, 240), QuestionBlock.Contents.COIN)
	sc.call("_add_question", Vector2(12 * 16, 240), QuestionBlock.Contents.MULTI_COIN)
	sc.call("_add_brick", Vector2(14 * 16, 240))
	sc.call("_add_brick", Vector2(15 * 16, 240))
	# Segment B: pipe chomp + cliffbug ledge lesson
	var pipe_x := 22 + (world % 4)
	sc.call("_add_pipe", Vector2(pipe_x * 16, 288), false)
	sc.call("_spawn_plant", Vector2(pipe_x * 16 + 16, 288))
	sc.call("_spawn_cliffbug", Vector2((pipe_x + 8) * 16, 300))
	sc.call("_spawn_browncap", Vector2((pipe_x + 14) * 16, 300))
	sc.call("_spawn_browncap", Vector2((pipe_x + 16) * 16, 300))
	# Segment C: mid power + ashbug / needler
	sc.call("_add_question", Vector2(40 * 16, 208), QuestionBlock.Contents.EMBER_BLOOM)
	_try_hidden_one_up(sc, 42)
	sc.call("_spawn_ashbug", Vector2(48 * 16, 300))
	if world >= 4:
		sc.call("_spawn_needler", Vector2(54 * 16, 300))
	# Segment D: climax (cannon / twins / hover)
	sc.call("_add_pipe", Vector2(62 * 16, 288), world % 2 == 0)
	sc.call("_spawn_plant", Vector2(62 * 16 + 16, 288))
	if world >= 5:
		sc.call("_spawn_iron_snout", Vector2(70 * 16, 304), -1.0)
		sc.call("_spawn_iron_snout", Vector2(88 * 16, 304), -1.0)
	if world >= 3:
		sc.call("_spawn_hoverbug", Vector2(76 * 16, 200))
		sc.call("_spawn_hoverbug", Vector2(92 * 16, 180))
	if world >= 6:
		_toss_pair(sc, 100)
	if world >= 4 and stage == 1:
		sc.call("_spawn_cloud", Vector2(110 * 16, 100))
	# Optional warps
	if world == 3 and stage == 1:
		sc.call("_add_warp", Vector2((w - 30) * 16, 272), 4, 1)
	if world == 5 and stage == 1:
		sc.call("_add_warp", Vector2((w - 28) * 16, 272), 6, 2)
	_scatter_enemies(sc, world, stage, w, 1.15)
	_stairs(sc, w - 14, 6)
	sc.call("_spawn_goal", Vector2((w - 8) * 16, 320))

static func _build_under(sc: Node, world: int, stage: int) -> void:
	var w := Catalog.level_width_tiles(world, stage)
	sc.call("_build_ground", w, _pits(world, stage, w))
	for x in range(0, w):
		sc.call("_add_solid", Vector2(x * 16, 0), Color("1b263b"))
	# Maze-ish brick columns
	for col in [18, 28, 38, 52, 68, 84]:
		if col >= w - 16:
			break
		for j in range(2 + (col % 3)):
			sc.call("_add_brick", Vector2(col * 16, 320 - (j + 3) * 16))
	sc.call("_add_question", Vector2(8 * 16, 240), QuestionBlock.Contents.BIG_BERRY)
	sc.call("_add_question", Vector2(9 * 16, 240), QuestionBlock.Contents.EMBER_BLOOM)
	sc.call("_add_question", Vector2(10 * 16, 240), QuestionBlock.Contents.MULTI_COIN)
	sc.call("_add_pipe", Vector2(16 * 16, 288), false)
	sc.call("_spawn_plant", Vector2(16 * 16 + 16, 288))
	sc.call("_spawn_cliffbug", Vector2(24 * 16, 300))
	sc.call("_spawn_ashbug", Vector2(36 * 16, 300))
	sc.call("_spawn_ashbug", Vector2(58 * 16, 300))
	if world >= 4:
		sc.call("_spawn_needler", Vector2(44 * 16, 300))
		sc.call("_spawn_needler", Vector2(72 * 16, 300))
	if world == 4 and stage == 2:
		sc.call("_add_warp", Vector2(46 * 16, 240), 6, 1)
	if world >= 6:
		sc.call("_spawn_iron_snout", Vector2(90 * 16, 304), -1.0)
	_scatter_enemies(sc, world, stage, w, 1.25)
	_stairs(sc, w - 12, 7)
	sc.call("_spawn_goal", Vector2((w - 6) * 16, 320))

static func _build_water(sc: Node, world: int, stage: int) -> void:
	var w := Catalog.level_width_tiles(world, stage)
	sc.call("_build_ground", w, _pits(world, stage, w))
	var water := WaterZone.new()
	water.configure(Vector2(w * 16, 280))
	water.position = Vector2(0, 80)
	sc.get_node("Entities").add_child(water)
	sc.call("_add_question", Vector2(8 * 16, 200), QuestionBlock.Contents.BIG_BERRY)
	sc.call("_add_question", Vector2(24 * 16, 180), QuestionBlock.Contents.MULTI_COIN)
	sc.call("_add_question", Vector2(48 * 16, 160), QuestionBlock.Contents.EMBER_BLOOM)
	for i in range(4 + world / 2):
		var x := (14 + i * 18) * 16
		sc.call("_spawn_swimfin", Vector2(x, 180 + (i % 3) * 20))
	sc.call("_spawn_inkjet", Vector2(40 * 16, 160))
	sc.call("_spawn_inkjet", Vector2(70 * 16, 140))
	if world >= 7:
		sc.call("_spawn_swimfin", Vector2(100 * 16, 200))
		sc.call("_spawn_inkjet", Vector2(112 * 16, 150))
	_scatter_enemies(sc, world, stage, w, 0.35)
	sc.call("_spawn_goal", Vector2((w - 8) * 16, 320))

static func _build_athletic(sc: Node, world: int, stage: int) -> void:
	var w := Catalog.level_width_tiles(world, stage)
	# Athletic: mostly pits with platforms
	var pits: Array = [[10, w - 16]]
	sc.call("_build_ground", w, pits)
	sc.call("_add_question", Vector2(8 * 16, 224), QuestionBlock.Contents.BIG_BERRY)
	sc.call("_add_question", Vector2(20 * 16, 192), QuestionBlock.Contents.SPARK_STAR)
	sc.call("_add_question", Vector2(56 * 16, 208), QuestionBlock.Contents.EMBER_BLOOM)
	sc.call("_add_question", Vector2(80 * 16, 176), QuestionBlock.Contents.MULTI_COIN)
	for x in range(24, 30):
		sc.call("_add_brick", Vector2(x * 16, 240))
	for x in range(44, 48):
		sc.call("_add_solid", Vector2(x * 16, 256), Color("6d4c41"))
	sc.call("_add_spring", Vector2(18 * 16, 256))
	sc.call("_add_spring", Vector2(64 * 16, 240))
	sc.call("_add_mover", Vector2(32 * 16, 220), Vector2(96, 0), 2.6 - world * 0.04)
	sc.call("_add_mover", Vector2(52 * 16, 180), Vector2(0, 64), 2.0)
	sc.call("_add_mover", Vector2(96 * 16, 200), Vector2(72, -24), 2.4)
	sc.call("_spawn_hoverbug", Vector2(28 * 16, 180))
	sc.call("_spawn_hoverbug", Vector2(72 * 16, 160))
	sc.call("_spawn_cliffbug", Vector2(46 * 16, 240))
	if world >= 5:
		sc.call("_spawn_cloud", Vector2(88 * 16, 100))
		sc.call("_spawn_needler", Vector2(100 * 16, 300))
	if world >= 6:
		_toss_pair(sc, 108)
	_scatter_enemies(sc, world, stage, w, 0.9, true)
	_stairs(sc, w - 12, 5 + world % 3)
	sc.call("_spawn_goal", Vector2((w - 6) * 16, 320))

static func _build_castle(sc: Node, world: int, stage: int) -> void:
	var w := Catalog.level_width_tiles(world, stage)
	var hall := w + 14
	sc.call("_build_ground", 40, [])
	for x in range(0, hall):
		sc.call("_add_solid", Vector2(x * 16, 0), Color("2c1e3a"))
	# Fire-bar gauntlet
	sc.call("_add_question", Vector2(8 * 16, 200), QuestionBlock.Contents.EMBER_BLOOM)
	sc.call("_spawn_fire_bar", Vector2(14 * 16, 260), 4 + world % 3, 1.35 + world * 0.04)
	sc.call("_spawn_fire_bar", Vector2(22 * 16, 240), 5 + world % 2, -1.45)
	sc.call("_spawn_fire_bar", Vector2(30 * 16, 250), 6, 1.6)
	sc.call("_spawn_ashbug", Vector2(18 * 16, 300))
	sc.call("_spawn_ashbug", Vector2(26 * 16, 300))
	# Lava bridge + ember blobs
	var lava := LavaHazard.new()
	lava.configure(18 + world, 2)
	lava.position = Vector2(40 * 16, 320)
	sc.get_node("Entities").add_child(lava)
	for bx in [44, 50, 56, 62]:
		sc.call("_spawn_ember_blob", Vector2(bx * 16, 320))
	var bridge: Array = []
	var bridge_end := 58 + world
	for x in range(40, bridge_end):
		bridge.append(sc.call("_add_solid_ref", Vector2(x * 16, 288), Color("7f8c8d")))
	for x in range(bridge_end, hall):
		sc.call("_add_solid", Vector2(x * 16, 320), Color("2c1e3a"))
	var final_boss := world >= Catalog.MAX_WORLDS
	var duke := sc.call("_spawn_duke", Vector2(48 * 16, 280), final_boss) as DukeSpikes
	if duke:
		duke.set_meta("min_x", 42.0 * 16)
		duke.set_meta("max_x", float(bridge_end - 2) * 16)
	var axe := AxeGoal.new()
	axe.collision_layer = 32
	axe.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 20)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	axe.add_child(shape)
	axe.position = Vector2((bridge_end - 1) * 16 + 8, 288)
	axe.monitoring = true
	axe.bind_bridge(bridge)
	axe.cleared.connect(Callable(sc, "_on_world_cleared"))
	sc.get_node("Entities").add_child(axe)

static func _try_hidden_one_up(sc: Node, tile_x: int) -> void:
	if sc.has_method("_add_hidden"):
		sc.call("_add_hidden", Vector2(tile_x * 16, 176), HiddenBlock.Contents.ONE_UP)

static func _toss_pair(sc: Node, tile_x: int) -> void:
	for x in range(tile_x, tile_x + 3):
		sc.call("_add_brick", Vector2(x * 16, 256))
		sc.call("_add_brick", Vector2(x * 16, 192))
	sc.call("_spawn_toss_twin", Vector2((tile_x + 1) * 16, 240))
	sc.call("_spawn_toss_twin", Vector2((tile_x + 1) * 16, 176))

static func _pits(world: int, stage: int, width: int) -> Array:
	var pits: Array = []
	var count := 2 + int(world / 2) + (1 if stage >= 2 else 0)
	for i in count:
		var s := Catalog.seed(world, stage, i)
		var start := 16 + (s % maxi(1, width - 36))
		var len := 2 + (s % 4)
		len = maxi(1, int(round(float(len) * 0.8)))
		pits.append([start, mini(start + len - 1, width - 6)])
	return pits

static func _pick_item(world: int, stage: int, slot: int) -> int:
	var s := Catalog.seed(world, stage, slot + 9) % 6
	match s:
		0:
			return QuestionBlock.Contents.COIN
		1:
			return QuestionBlock.Contents.BIG_BERRY
		2:
			return QuestionBlock.Contents.EMBER_BLOOM
		3:
			return QuestionBlock.Contents.SPARK_STAR
		4:
			return QuestionBlock.Contents.MULTI_COIN
		_:
			return QuestionBlock.Contents.COIN

static func _scatter_enemies(sc: Node, world: int, stage: int, width: int, density_mul: float = 1.0, winged: bool = false) -> void:
	var n := int((4 + world + stage) * density_mul)
	for i in n:
		var s := Catalog.seed(world, stage, 40 + i)
		var x := (10 + (s % maxi(1, width - 20))) * 16
		var roll := s % 8
		match roll:
			0, 1:
				sc.call("_spawn_browncap", Vector2(x, 300))
			2:
				sc.call("_spawn_shellbug", Vector2(x, 300), winged and i % 3 == 0)
			3:
				sc.call("_spawn_cliffbug", Vector2(x, 300))
			4:
				if world >= 4:
					sc.call("_spawn_ashbug", Vector2(x, 300))
				else:
					sc.call("_spawn_browncap", Vector2(x, 300))
			5:
				if world >= 5:
					sc.call("_spawn_needler", Vector2(x, 300))
				else:
					sc.call("_spawn_shellbug", Vector2(x, 300), false)
			6:
				if winged:
					sc.call("_spawn_hoverbug", Vector2(x, 200))
				else:
					sc.call("_spawn_shellbug", Vector2(x, 300), true)
			_:
				sc.call("_spawn_browncap", Vector2(x, 300))

static func _stairs(sc: Node, base_x: int, steps: int) -> void:
	for i in range(steps):
		for j in range(i + 1):
			sc.call("_add_solid", Vector2((base_x + i) * 16, 320 - (j + 1) * 16), Color("6d4c41"))
