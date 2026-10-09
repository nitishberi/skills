extends CharacterBody2D
class_name DukeSpikes

signal defeated

const GRAVITY := 900.0
const PACE := 50.0

var dir: float = -1.0
var dead: bool = false
var ember_hits: int = 0
var is_final: bool = false
var hits_needed: int = 5

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("duke_spikes")
	hits_needed = 8 if is_final else 5
	_build_visual()

func _build_visual() -> void:
	var body := ColorRect.new()
	body.name = "Body"
	body.size = Vector2(28, 28)
	body.position = Vector2(-14, -28)
	# Fake dukes are duller purple; final is richer
	body.color = Color("5b2c6f") if is_final else Color("7d3c98")
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	var spike := ColorRect.new()
	spike.size = Vector2(8, 10)
	spike.position = Vector2(-4, -38)
	spike.color = Color("d5d8dc")
	spike.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spike)
	if not is_final:
		var tag := Label.new()
		tag.text = "IMPOSTOR"
		tag.position = Vector2(-22, -48)
		tag.add_theme_font_size_override("font_size", 8)
		tag.add_theme_color_override("font_color", Color("f5b041"))
		add_child(tag)

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = dir * (PACE + (10.0 if is_final else 0.0))
	if has_meta("min_x") and global_position.x < float(get_meta("min_x")):
		dir = 1.0
	if has_meta("max_x") and global_position.x > float(get_meta("max_x")):
		dir = -1.0
	if is_on_wall():
		dir *= -1.0
	move_and_slide()

func stomp() -> void:
	pass

func hit_by_ember() -> void:
	if dead:
		return
	ember_hits += 1
	modulate = Color(1.5, 1.2, 1.2)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	if ember_hits >= hits_needed:
		_defeat()

func drop_into_lava() -> void:
	_defeat()

func _defeat() -> void:
	if dead:
		return
	dead = true
	if is_final:
		RunState.add_score(5000)
	else:
		# Impostor reveal: brief flash then score
		RunState.add_score(2000)
		var decoy := ColorRect.new()
		decoy.size = Vector2(14, 14)
		decoy.color = Color("3d8b6e")
		decoy.global_position = global_position + Vector2(-7, -14)
		get_tree().current_scene.add_child(decoy)
		var t := decoy.create_tween()
		t.tween_property(decoy, "modulate:a", 0.0, 0.6)
		t.tween_callback(decoy.queue_free)
	defeated.emit()
	queue_free()
