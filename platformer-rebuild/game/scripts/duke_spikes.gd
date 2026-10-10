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
	var s := Art.make_sprite("duke_final" if is_final else "duke_fake", true)
	add_child(s)
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
		RunState.add_score(2000)
		var decoy := Art.make_sprite("shellbug", true)
		decoy.global_position = global_position
		get_tree().current_scene.add_child(decoy)
		var t := decoy.create_tween()
		t.tween_property(decoy, "modulate:a", 0.0, 0.6)
		t.tween_callback(decoy.queue_free)
	defeated.emit()
	queue_free()
