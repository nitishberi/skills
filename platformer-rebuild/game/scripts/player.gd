extends CharacterBody2D
class_name CapPlayer

const FxScript := preload("res://scripts/fx.gd")

signal died
signal form_changed(form: String)

const WALK_SPEED := 120.0
const RUN_SPEED := 180.0
const ACCEL := 900.0
const FRICTION := 1100.0
const JUMP_VELOCITY := -320.0
const JUMP_CUT := 0.45
const GRAVITY := 900.0
const MAX_FALL := 420.0
const COYOTE := 0.08
const JUMP_BUFFER := 0.1

var facing: float = 1.0
var coyote_t: float = 0.0
var jump_buf: float = 0.0
var hurt_cooldown: float = 0.0
var shoot_cooldown: float = 0.0
var in_water: bool = false
var _sprite: Sprite2D
var _anim_t: float = 0.0
var _walk_frame: int = 0

@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("player")
	_sprite = Art.make_sprite("cap_small_walk_0", true)
	add_child(_sprite)
	_apply_form_visual(RunState.form)
	RunState.changed.connect(_on_run_changed)

func _layout_collision(form: String) -> void:
	var tall := form != "small"
	var h := 28.0 if tall else 16.0
	var w := 12.0
	if collision.shape is RectangleShape2D:
		var rect := collision.shape as RectangleShape2D
		rect.size = Vector2(w, h)
		collision.position = Vector2(0, -h * 0.5)

func _apply_form_visual(form: String) -> void:
	_layout_collision(form)
	_refresh_sprite(0.0, true)

func _on_run_changed() -> void:
	_apply_form_visual(RunState.form)

func _refresh_sprite(delta: float, force: bool = false) -> void:
	var airborne := not is_on_floor()
	if absf(velocity.x) > 8.0 and is_on_floor():
		_anim_t += delta
		if _anim_t > 0.12:
			_anim_t = 0.0
			_walk_frame = 1 - _walk_frame
	elif force:
		_walk_frame = 0
	var key := Art.player_texture(RunState.form, _walk_frame, airborne)
	_sprite.texture = Art.texture(key)
	_sprite.flip_h = facing < 0.0

func _physics_process(delta: float) -> void:
	if hurt_cooldown > 0.0:
		hurt_cooldown -= delta
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta
	if RunState.invuln_timer > 0.0:
		RunState.invuln_timer = maxf(0.0, RunState.invuln_timer - delta)
		modulate.a = 0.55 if int(RunState.invuln_timer * 20) % 2 == 0 else 1.0
	else:
		modulate.a = 1.0

	if in_water:
		velocity.y = minf(160.0, velocity.y + 220.0 * delta)
		if Input.is_action_just_pressed("jump"):
			velocity.y = -180.0
			Sfx.play("jump")
		if Input.is_action_pressed("move_down"):
			velocity.y = minf(200.0, velocity.y + 40.0)
	else:
		if not is_on_floor():
			velocity.y = minf(MAX_FALL, velocity.y + GRAVITY * delta)
			coyote_t = maxf(0.0, coyote_t - delta)
		else:
			coyote_t = COYOTE
		if Input.is_action_just_pressed("jump"):
			jump_buf = JUMP_BUFFER
		else:
			jump_buf = maxf(0.0, jump_buf - delta)
		if jump_buf > 0.0 and coyote_t > 0.0:
			velocity.y = JUMP_VELOCITY
			jump_buf = 0.0
			coyote_t = 0.0
			Sfx.play("jump")
		if Input.is_action_just_released("jump") and velocity.y < 0.0:
			velocity.y *= JUMP_CUT

	var dir := Input.get_axis("move_left", "move_right")
	var speed := (RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED)
	if in_water:
		speed *= 0.75
	if dir != 0.0:
		facing = signf(dir)
		velocity.x = move_toward(velocity.x, dir * speed, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	if RunState.form == "fire" and Input.is_action_just_pressed("run") and shoot_cooldown <= 0.0:
		_shoot_ember()

	move_and_slide()
	_resolve_collisions()
	_refresh_sprite(delta)

	if global_position.y > 420.0:
		_die()

func _shoot_ember() -> void:
	shoot_cooldown = 0.35
	var shot := EmberShot.new()
	shot.dir = facing if facing != 0.0 else 1.0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4
	shape.shape = circle
	shot.add_child(shape)
	shot.monitoring = true
	shot.monitorable = true
	shot.global_position = global_position + Vector2(facing * 10.0, -12.0)
	get_tree().current_scene.add_child(shot)

func _resolve_collisions() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider == null:
			continue
		var normal := col.get_normal()
		if normal.y > 0.5 and velocity.y < 0.0:
			if collider.is_in_group("question_blocks") and collider.has_method("bump_from_below"):
				collider.bump_from_below()
			elif collider.is_in_group("breakable_bricks") and collider.has_method("bump_from_below"):
				collider.bump_from_below()
		if collider.is_in_group("enemies"):
			_touch_enemy(collider, normal)
		elif collider.is_in_group("hazards"):
			_die()
		elif collider.is_in_group("pickups"):
			if collider.has_method("collect"):
				collider.collect(self)
		elif collider.is_in_group("goal"):
			if collider.has_method("activate"):
				collider.activate()

func _touch_enemy(enemy: Node, normal: Vector2) -> void:
	if RunState.invuln_timer > 0.0:
		if enemy.has_method("hit_by_ember"):
			enemy.hit_by_ember()
		elif enemy.has_method("stomp"):
			enemy.stomp()
		return
	if enemy.is_in_group("duke_spikes"):
		_take_hit()
		return
	if normal.y < -0.5 and velocity.y >= 0.0:
		if enemy.has_method("stomp"):
			enemy.stomp()
			velocity.y = JUMP_VELOCITY * 0.55
			RunState.add_score(100)
			Sfx.play("stomp")
			_shake(3.0)
			FxScript.stomp_dust(get_tree().current_scene, global_position)
		return
	if enemy is Shellbug and (enemy as Shellbug).is_shell_idle():
		(enemy as Shellbug).stomp()
		return
	_take_hit()

func _take_hit() -> void:
	if hurt_cooldown > 0.0:
		return
	hurt_cooldown = 1.0
	Sfx.play("hurt")
	_shake(5.0)
	if RunState.form == "fire" or RunState.form == "tall":
		RunState.set_form("small")
		RunState.invuln_timer = 1.5
		form_changed.emit(RunState.form)
	else:
		_die()

func grow() -> void:
	if RunState.form == "small":
		RunState.set_form("tall")
		form_changed.emit(RunState.form)
	RunState.add_score(1000)
	Sfx.play("power")

func grant_fire() -> void:
	if RunState.form == "small":
		RunState.set_form("tall")
	RunState.set_form("fire")
	form_changed.emit(RunState.form)
	RunState.add_score(1000)
	Sfx.play("power")

func grant_invuln(seconds: float = 6.0) -> void:
	RunState.invuln_timer = seconds
	modulate = Color(1.3, 1.25, 0.7)
	RunState.add_score(1000)
	Sfx.play("power")

func _shake(amount: float) -> void:
	var cam := get_tree().get_first_node_in_group("game_camera")
	if cam and cam.has_method("shake"):
		cam.shake(amount)

func _die() -> void:
	Sfx.play("hurt")
	died.emit()
