extends Node2D

const TILE := 16

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("1b263b"))
	Music.play_theme("under")
	_build()
	_spawn_player(Vector2(64, 304))
	add_child(preload("res://scenes/hud.tscn").instantiate())
	add_child(preload("res://scenes/pause_layer.tscn").instantiate())

func _build() -> void:
	for x in range(0, 30):
		_solid(Vector2(x * TILE, 320), Color("415a77"))
		_solid(Vector2(x * TILE, 336), Color("1b263b"))
		_solid(Vector2(x * TILE, 0), Color("1b263b"))
	for x in range(4, 20):
		_solid(Vector2(x * TILE, 240), Color("5d6d7e"))
	for i in range(12):
		_coin(Vector2((5 + i) * TILE + 8, 220))
	# Exit pipe visual + zone
	for y in [288, 304]:
		_solid(Vector2(24 * TILE, y), Color("2a9d8f"))
		_solid(Vector2(25 * TILE, y), Color("2a9d8f"))
	var exit := Area2D.new()
	exit.collision_layer = 0
	exit.collision_mask = 2
	exit.monitoring = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 20)
	shape.shape = rect
	shape.position = Vector2(8, -10)
	exit.add_child(shape)
	exit.position = Vector2(24 * TILE + 8, 288)
	exit.body_entered.connect(_on_exit)
	add_child(exit)
	var tip := Label.new()
	tip.text = "BONUS  Walk into the teal pipe to leave"
	tip.position = Vector2(16, 40)
	tip.add_theme_font_size_override("font_size", 12)
	tip.add_theme_color_override("font_color", Color("ecf0f1"))
	add_child(tip)

func _solid(pos: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	shape.shape = rect
	shape.position = Vector2(8, 8)
	body.add_child(shape)
	body.add_child(Art.make_sprite(Art.tile_key_for_color(color), false))
	add_child(body)

func _coin(pos: Vector2) -> void:
	var c := HopCoin.new()
	c.collision_layer = 8
	c.collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5
	shape.shape = circle
	c.add_child(shape)
	c.position = pos
	c.monitoring = true
	add_child(c)

func _spawn_player(pos: Vector2) -> void:
	var p := CapPlayer.new()
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
	add_child(p)

func _on_exit(body: Node) -> void:
	if body is CapPlayer:
		RenderingServer.set_default_clear_color(Color("7ec8e3"))
		RunState.use_pipe_spawn = true
		var scene := RunState.pipe_return_scene
		if scene == "":
			scene = RunState.scene_for_current_stage()
		get_tree().change_scene_to_file(scene)
