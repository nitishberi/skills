extends RefCounted

const Catalog := preload("res://scripts/level_catalog.gd")

static func build(sc: Node, world: int, stage: int) -> void:
	if Catalog.is_handcrafted(world, stage):
		_build_handcrafted(sc, world, stage)
	else:
		_build_procedural(sc, world, stage)

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
			_build_procedural(sc, world, stage)

static func _build_procedural(sc: Node, world: int, stage: int) -> void:
	var kind := Catalog.stage_kind(world, stage)
	match kind:
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
	for i in 3:
		var bx := 8 + i * 2 + world % 3
		sc.call("_add_question", Vector2(bx * 16, 240), _pick_item(world, stage, i))
	sc.call("_add_question", Vector2((14 + world % 4) * 16, 240), QuestionBlock.Contents.ONE_UP if world % 3 == 0 else QuestionBlock.Contents.COIN)
	if world == 3 and stage == 1:
		sc.call("_add_warp", Vector2(58 * 16, 272), 4, 1)
	sc.call("_add_pipe", Vector2((20 + world * 2) * 16, 288), world % 2 == 0)
	_scatter_enemies(sc, world, stage, w)
	_stairs(sc, w - 12, 5)
	sc.call("_spawn_goal", Vector2((w - 8) * 16, 320))

static func _build_under(sc: Node, world: int, stage: int) -> void:
	var w := Catalog.level_width_tiles(world, stage)
	sc.call("_build_ground", w, _pits(world, stage, w))
	for x in range(0, w):
		sc.call("_add_solid", Vector2(x * 16, 0), Color("1b263b"))
	sc.call("_add_question", Vector2(8 * 16, 240), QuestionBlock.Contents.BIG_BERRY)
	sc.call("_add_question", Vector2(9 * 16, 240), QuestionBlock.Contents.EMBER_BLOOM)
	sc.call("_add_question", Vector2(10 * 16, 240), QuestionBlock.Contents.COIN)
	sc.call("_add_pipe", Vector2(16 * 16, 288), false)
	sc.call("_spawn_plant", Vector2(16 * 16 + 16, 288))
	if world == 4 and stage == 2:
		sc.call("_add_warp", Vector2(46 * 16, 240), 6, 1)
	_scatter_enemies(sc, world, stage, w, 1.2)
	_stairs(sc, w - 10, 6)
	sc.call("_spawn_goal", Vector2((w - 6) * 16, 320))

static func _build_water(sc: Node, world: int, stage: int) -> void:
	var w := Catalog.level_width_tiles(world, stage)
	sc.call("_build_ground", w, _pits(world, stage, w))
	var water := WaterZone.new()
	water.configure(Vector2(w * 16, 280))
	water.position = Vector2(0, 80)
	sc.get_node("Entities").add_child(water)
	sc.call("_add_question", Vector2(8 * 16, 200), QuestionBlock.Contents.BIG_BERRY)
	sc.call("_add_question", Vector2(30 * 16, 180), QuestionBlock.Contents.EMBER_BLOOM)
	_scatter_enemies(sc, world, stage, w, 0.9)
	sc.call("_spawn_goal", Vector2((w - 8) * 16, 320))

static func _build_athletic(sc: Node, world: int, stage: int) -> void:
	var w := Catalog.level_width_tiles(world, stage)
	sc.call("_build_ground", w, _pits(world, stage, w))
	sc.call("_add_question", Vector2(8 * 16, 224), QuestionBlock.Contents.BIG_BERRY)
	sc.call("_add_question", Vector2(20 * 16, 208), QuestionBlock.Contents.SPARK_STAR)
	sc.call("_add_question", Vector2(40 * 16, 224), QuestionBlock.Contents.EMBER_BLOOM)
	for x in range(24, 28):
		sc.call("_add_brick", Vector2(x * 16, 240))
	sc.call("_add_spring", Vector2(18 * 16, 256))
	sc.call("_add_mover", Vector2(32 * 16, 240), Vector2(80, 0), 2.8 - world * 0.05)
	sc.call("_add_mover", Vector2(52 * 16, 200), Vector2(0, 48), 2.2)
	if world >= 5:
		sc.call("_spawn_cloud", Vector2(60 * 16, 120))
	_scatter_enemies(sc, world, stage, w, 1.1, true)
	_stairs(sc, w - 10, 4 + world % 3)
	sc.call("_spawn_goal", Vector2((w - 6) * 16, 320))

static func _build_castle(sc: Node, world: int, stage: int) -> void:
	var w := Catalog.level_width_tiles(world, stage)
	var hall := w + 10
	sc.call("_build_ground", 36, [])
	for x in range(0, hall):
		sc.call("_add_solid", Vector2(x * 16, 0), Color("2c1e3a"))
	sc.call("_add_question", Vector2(8 * 16, 200), QuestionBlock.Contents.EMBER_BLOOM)
	sc.call("_spawn_fire_bar", Vector2(16 * 16, 260), 4 + world % 3, 1.4 + world * 0.05)
	sc.call("_spawn_fire_bar", Vector2(28 * 16, 240), 5 + world % 2, -1.5)
	var lava := LavaHazard.new()
	lava.configure(14 + world, 2)
	lava.position = Vector2(36 * 16, 320)
	sc.get_node("Entities").add_child(lava)
	var bridge: Array = []
	for x in range(36, 50 + world / 2):
		bridge.append(sc.call("_add_solid_ref", Vector2(x * 16, 288), Color("7f8c8d")))
	for x in range(50 + world / 2, hall):
		sc.call("_add_solid", Vector2(x * 16, 320), Color("2c1e3a"))
	var final_boss := world >= Catalog.MAX_WORLDS
	var duke := sc.call("_spawn_duke", Vector2(42 * 16, 280), final_boss) as DukeSpikes
	if duke:
		duke.set_meta("min_x", 37.0 * 16)
		duke.set_meta("max_x", (48 + world) * 16)
	var axe := AxeGoal.new()
	axe.collision_layer = 32
	axe.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 20)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	axe.add_child(shape)
	axe.position = Vector2((49 + world / 2) * 16 + 8, 288)
	axe.monitoring = true
	axe.bind_bridge(bridge)
	axe.cleared.connect(Callable(sc, "_on_world_cleared"))
	sc.get_node("Entities").add_child(axe)

static func _pits(world: int, stage: int, width: int) -> Array:
	var pits: Array = []
	var count := 1 + int(world / 2)
	for i in count:
		var s := Catalog.seed(world, stage, i)
		var start := 14 + (s % maxi(1, width - 24))
		var len := 2 + (s % 3)
		pits.append([start, mini(start + len, width - 4)])
	return pits

static func _pick_item(world: int, stage: int, slot: int) -> int:
	var s := Catalog.seed(world, stage, slot + 9) % 5
	match s:
		0:
			return QuestionBlock.Contents.COIN
		1:
			return QuestionBlock.Contents.BIG_BERRY
		2:
			return QuestionBlock.Contents.EMBER_BLOOM
		3:
			return QuestionBlock.Contents.SPARK_STAR
		_:
			return QuestionBlock.Contents.COIN

static func _scatter_enemies(sc: Node, world: int, stage: int, width: int, density_mul: float = 1.0, winged: bool = false) -> void:
	var n := int((2 + world / 2 + stage / 2) * density_mul)
	for i in n:
		var s := Catalog.seed(world, stage, 40 + i)
		var x := (8 + (s % (width - 16))) * 16
		if i % 2 == 0:
			sc.call("_spawn_browncap", Vector2(x, 300))
		else:
			sc.call("_spawn_shellbug", Vector2(x, 300), winged and i % 3 == 0)

static func _stairs(sc: Node, base_x: int, steps: int) -> void:
	for i in range(steps):
		for j in range(i + 1):
			sc.call("_add_solid", Vector2((base_x + i) * 16, 320 - (j + 1) * 16), Color("6d4c41"))
