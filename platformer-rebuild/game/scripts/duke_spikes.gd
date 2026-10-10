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
var _atk_cd: float = 1.2
var _hop_cd: float = 1.4

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("duke_spikes")
	hits_needed = 8 if is_final else 5
	if RunState.hard_quest:
		set_meta("speed_mul", SmbTuning.HARD_ENEMY_SPEED_MUL)
	var s := Art.make_sprite("duke_final" if is_final else "duke_fake", true)
	add_child(s)
	if not is_final:
		var tag := Label.new()
		tag.text = "IMPOSTOR"
		tag.position = Vector2(-22, -48)
		tag.add_theme_font_size_override("font_size", 8)
		tag.add_theme_color_override("font_color", Color("f5b041"))
		add_child(tag)

func _use_flame() -> bool:
	# Wiki: flame W1-5; hammers W6-7; both on W8 final.
	if is_final:
		return true
	return RunState.world <= 5

func _use_hammers() -> bool:
	if is_final:
		return true
	return RunState.world >= 6

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var mul := float(get_meta("speed_mul", 1.0))
	velocity.x = dir * (PACE + (10.0 if is_final else 0.0)) * mul
	if has_meta("min_x") and global_position.x < float(get_meta("min_x")):
		dir = 1.0
	if has_meta("max_x") and global_position.x > float(get_meta("max_x")):
		dir = -1.0
	if is_on_wall():
		dir *= -1.0
	_hop_cd -= delta
	if is_on_floor() and _hop_cd <= 0.0:
		velocity.y = -180.0
		_hop_cd = 1.6
	move_and_slide()
	_atk_cd -= delta
	if _atk_cd <= 0.0:
		_atk_cd = 1.5 if is_final else 1.9
		_attack()

func _attack() -> void:
	var p := get_tree().get_first_node_in_group("player")
	var face := -1.0
	if p and p is Node2D:
		face = signf((p as Node2D).global_position.x - global_position.x)
		if face == 0.0:
			face = dir
	if _use_flame():
		var f := DukeFlame.new()
		f.dir = face
		f.global_position = global_position + Vector2(face * 16.0, -18.0)
		get_tree().current_scene.add_child(f)
	if _use_hammers():
		var h := TossHammer.new()
		h.global_position = global_position + Vector2(face * 8.0, -20.0)
		h.velocity = Vector2(face * 100.0, -240.0)
		get_tree().current_scene.add_child(h)

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
	# Wiki: 5 fireballs → 5000 (also axe path).
	RunState.add_score(5000)
	if not is_final:
		var decoy := Art.make_sprite("mudbit", true)
		decoy.global_position = global_position
		get_tree().current_scene.add_child(decoy)
		var t := decoy.create_tween()
		t.tween_property(decoy, "modulate:a", 0.0, 0.6)
		t.tween_callback(decoy.queue_free)
	defeated.emit()
	queue_free()
