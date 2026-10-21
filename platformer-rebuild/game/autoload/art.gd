extends Node
## Procedural 16px pixel art (original palette; no Nintendo assets).

var _tex: Dictionary = {}

func _ready() -> void:
	_build_all()

func texture(key: String) -> Texture2D:
	return _tex.get(key, _tex["dirt"])

func make_sprite(key: String, centered_bottom: bool = true) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture(key)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	var sz := s.texture.get_size()
	if centered_bottom:
		# Feet / bottom-center at the node's origin (matches CharacterBody2D feet).
		s.offset = Vector2(-sz.x * 0.5, -sz.y)
	else:
		# Top-left at origin (tiles placed at tile corner).
		s.offset = Vector2.ZERO
	return s

func tile_key_for_color(c: Color) -> String:
	var h := c.to_html(false)
	match h:
		"5a3d2b":
			return "grass"
		"3e2723", "2c1e3a":
			return "dirt"
		"6d4c41", "a67c52":
			return "brick"
		"1b263b", "1a1423":
			return "ceiling"
		"7f8c8d", "415a77", "5d6d7e":
			return "stone"
		"2a9d8f":
			return "pipe_top"
		"1f7a6a":
			return "pipe_body"
		_:
			return "dirt"

func parallax_keys_for_clear(c: Color) -> PackedStringArray:
	var h := c.to_html(false)
	if h == "1a5276":
		return PackedStringArray(["para_cloud", "para_wave"])
	if h == "1a1423" or h == "1b263b":
		return PackedStringArray(["para_castle", "para_smoke"])
	if h == "1b263b":
		return PackedStringArray(["para_under", "para_under2"])
	return PackedStringArray(["para_hill_far", "para_hill_near", "para_cloud"])

func player_texture(form: String, walk_frame: int, airborne: bool) -> String:
	if airborne:
		match form:
			"fire":
				return "cap_fire_jump"
			"tall":
				return "cap_tall_jump"
			_:
				return "cap_small_jump"
	var f := walk_frame % 2
	match form:
		"fire":
			return "cap_fire_walk_%d" % f
		"tall":
			return "cap_tall_walk_%d" % f
		_:
			return "cap_small_walk_%d" % f

func _build_all() -> void:
	_tex["grass"] = _t(_draw_grass())
	_tex["dirt"] = _t(_draw_dirt())
	_tex["brick"] = _t(_draw_brick())
	_tex["ceiling"] = _t(_draw_ceiling())
	_tex["stone"] = _t(_draw_stone())
	_tex["pipe_top"] = _t(_draw_pipe(true))
	_tex["pipe_body"] = _t(_draw_pipe(false))
	_tex["question"] = _t(_draw_question(false))
	_tex["question_used"] = _t(_draw_question(true))
	_tex["hidden"] = _t(_draw_hidden())
	_tex["coin"] = _t(_draw_coin())
	# Rise Melon / Blaze Bud / Zap Star / Extra Melon (replaced berry/ember/star/one_up look).
	_tex["berry"] = _t(_draw_rise_melon())
	_tex["rise_melon"] = _tex["berry"]
	_tex["ember"] = _t(_draw_blaze_bud())
	_tex["blaze_bud"] = _tex["ember"]
	_tex["star"] = _t(_draw_zap_star())
	_tex["zap_star"] = _tex["star"]
	_tex["one_up"] = _t(_draw_extra_melon())
	_tex["extra_melon"] = _tex["one_up"]
	_tex["mudbit"] = _t(_draw_mudbit())
	_tex["browncap"] = _tex["mudbit"]
	_tex["coilbug"] = _t(_draw_coilbug(false))
	_tex["coilbug_shell"] = _t(_draw_coilbug(true))
	_tex["shellbug"] = _tex["coilbug"]
	_tex["shellbug_shell"] = _tex["coilbug_shell"]
	_tex["cliffbug"] = _t(_draw_cliffbug(false))
	_tex["ashbug"] = _t(_draw_ashbug(false))
	_tex["ashbug_shell"] = _t(_draw_ashbug(true))
	_tex["wing"] = _t(_draw_wing())
	_tex["duke_fake"] = _t(_draw_duke(false))
	_tex["duke_final"] = _t(_draw_duke(true))
	_tex["duke_flame"] = _t(_draw_duke_flame())
	_tex["plant"] = _t(_draw_pipe_chomp())
	_tex["pipe_chomp"] = _tex["plant"]
	_tex["cloud"] = _t(_draw_sky_rider())
	_tex["sky_rider"] = _tex["cloud"]
	_tex["spike"] = _t(_draw_spike())
	_tex["needler"] = _t(_draw_needler())
	_tex["needler_egg"] = _t(_draw_needler_egg())
	_tex["cannon"] = _t(_draw_cannon())
	_tex["pipe_shot"] = _t(_draw_pipe_shot())
	_tex["swimfin"] = _t(_draw_swimfin())
	_tex["inkjet"] = _t(_draw_inkjet())
	_tex["ember_blob"] = _t(_draw_ember_blob())
	_tex["toss_twin"] = _t(_draw_toss_twin())
	_tex["hammer"] = _t(_draw_hammer())
	_tex["spring"] = _t(_draw_spring())
	_tex["mover"] = _t(_draw_mover())
	_tex["ember_shot"] = _t(_draw_ember_shot())
	_tex["flag_pole"] = _t(_draw_flag_pole())
	_tex["flag_cloth"] = _t(_draw_flag_cloth())
	_tex["firework"] = _t(_draw_firework())
	_tex["axe"] = _t(_draw_axe())
	_tex["fire_orb"] = _t(_draw_fire_orb())
	_tex["lava"] = _t(_draw_lava())
	_tex["water"] = _t(_draw_water())
	_tex["para_hill_far"] = _t(_draw_hill(Color("6ab04c"), 96, 48))
	_tex["para_hill_near"] = _t(_draw_hill(Color("78e08f"), 128, 56))
	_tex["para_cloud"] = _t(_draw_para_cloud())
	_tex["para_wave"] = _t(_draw_wave())
	_tex["para_castle"] = _t(_draw_castle_sil())
	_tex["para_smoke"] = _t(_draw_smoke())
	_tex["para_under"] = _t(_draw_under_bg())
	_tex["para_under2"] = _t(_draw_under_stal())
	for form in ["small", "tall", "fire"]:
		for i in 2:
			_tex["cap_%s_walk_%d" % [form, i]] = _t(_draw_cap(form, i, false))
		if form == "small":
			_tex["cap_small_jump"] = _t(_draw_cap("small", 0, true))
		else:
			_tex["cap_%s_jump" % form] = _t(_draw_cap(form, 0, true))

func _img(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

func _t(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, c)

func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_px(img, xx, yy, c)

func _draw_grass() -> Image:
	var img := _img(16, 16)
	_rect(img, 0, 6, 16, 10, Color("3e2723"))
	_rect(img, 0, 4, 16, 4, Color("5a3d2b"))
	for x in range(0, 16, 2):
		_px(img, x, 3, Color("78e08f"))
		_px(img, x + 1, 2, Color("6ab04c"))
	_px(img, 5, 2, Color("badc58"))
	_px(img, 11, 3, Color("badc58"))
	_rect(img, 0, 8, 16, 1, Color("2e1f18"))
	return img

func _draw_dirt() -> Image:
	var img := _img(16, 16)
	_rect(img, 0, 0, 16, 16, Color("3e2723"))
	for i in range(8):
		_px(img, (i * 3) % 16, (i * 5) % 16, Color("4e342e"))
	return img

func _draw_brick() -> Image:
	var img := _img(16, 16)
	_rect(img, 0, 0, 16, 16, Color("a67c52"))
	for row in 2:
		var off := 0 if row == 0 else 8
		for col in 2:
			var x := col * 8 + off % 8
			_rect(img, x, row * 8, 7, 7, Color("8d6e63"))
			_rect(img, x, row * 8, 7, 1, Color("6d4c41"))
	return img

func _draw_ceiling() -> Image:
	var img := _img(16, 16)
	_rect(img, 0, 0, 16, 16, Color("1b263b"))
	for i in range(6):
		_px(img, i * 3, (i * 2) % 16, Color("2c3e50"))
	return img

func _draw_stone() -> Image:
	var img := _img(16, 16)
	_rect(img, 0, 0, 16, 16, Color("7f8c8d"))
	_rect(img, 1, 1, 14, 14, Color("95a5a6"))
	return img

func _draw_pipe(top: bool) -> Image:
	var img := _img(16, 16)
	var main := Color("2a9d8f") if top else Color("1f7a6a")
	_rect(img, 2, 0, 12, 16, main)
	_rect(img, 0, 0 if top else 2, 2, 14, Color("145a52"))
	_rect(img, 14, 0 if top else 2, 2, 14, Color("145a52"))
	if top:
		_rect(img, 0, 0, 16, 4, Color("38b2a3"))
		_rect(img, 4, 1, 8, 2, Color("1f7a6a"))
	return img

func _draw_question(used: bool) -> Image:
	var img := _img(16, 16)
	var base := Color("7f8c8d") if used else Color("e8a838")
	_rect(img, 0, 0, 16, 16, base)
	_rect(img, 1, 1, 14, 14, base.lightened(0.08 if not used else -0.12))
	if not used:
		_rect(img, 6, 4, 4, 8, Color("264653"))
		_px(img, 7, 5, Color("e8a838"))
	else:
		_rect(img, 4, 6, 8, 2, Color("566573"))
	return img

func _draw_hidden() -> Image:
	var img := _img(16, 16)
	_rect(img, 0, 0, 16, 16, Color(1, 1, 1, 0.05))
	_rect(img, 2, 2, 12, 12, Color("e8a838", 0.35))
	return img

func _draw_coin() -> Image:
	var img := _img(10, 12)
	_rect(img, 2, 1, 6, 10, Color("f39c12"))
	_rect(img, 3, 2, 4, 8, Color("f1c40f"))
	_px(img, 4, 3, Color("fdebd0"))
	return img

func _draw_rise_melon() -> Image:
	var img := _img(14, 14)
	_rect(img, 2, 4, 10, 8, Color("e74c3c"))
	_rect(img, 4, 2, 6, 4, Color("c0392b"))
	_px(img, 6, 1, Color("27ae60"))
	_px(img, 7, 0, Color("2ecc71"))
	_px(img, 5, 7, Color("fff3e0"))
	return img

func _draw_blaze_bud() -> Image:
	var img := _img(14, 14)
	_rect(img, 5, 8, 4, 5, Color("27ae60"))
	_rect(img, 3, 3, 8, 6, Color("e67e22"))
	_px(img, 6, 4, Color("f9ca24"))
	_px(img, 8, 5, Color("f39c12"))
	return img

func _draw_zap_star() -> Image:
	var img := _img(14, 14)
	_px(img, 7, 1, Color("f1c40f"))
	_px(img, 7, 2, Color("f9ca24"))
	_rect(img, 4, 5, 6, 4, Color("f1c40f"))
	_px(img, 2, 6, Color("f9ca24"))
	_px(img, 11, 6, Color("f9ca24"))
	_px(img, 7, 10, Color("f1c40f"))
	_px(img, 5, 11, Color("f39c12"))
	_px(img, 9, 11, Color("f39c12"))
	return img

func _draw_extra_melon() -> Image:
	var img := _img(14, 14)
	_rect(img, 2, 4, 10, 8, Color("27ae60"))
	_rect(img, 4, 2, 6, 4, Color("1e8449"))
	_px(img, 6, 1, Color("2ecc71"))
	_rect(img, 5, 7, 4, 2, Color("145a32"))
	return img

func _draw_mudbit() -> Image:
	var img := _img(16, 16)
	_rect(img, 2, 5, 12, 9, Color("6e2c00"))
	_rect(img, 3, 3, 10, 4, Color("935116"))
	_px(img, 5, 7, Color("fff8e7"))
	_px(img, 6, 7, Color("1c2833"))
	_px(img, 10, 7, Color("fff8e7"))
	_px(img, 11, 7, Color("1c2833"))
	_rect(img, 4, 12, 3, 2, Color("4a235a"))
	_rect(img, 9, 12, 3, 2, Color("4a235a"))
	return img

func _draw_coilbug(shell: bool) -> Image:
	var img := _img(16, 14)
	if shell:
		_rect(img, 1, 4, 14, 8, Color("1a5276"))
		for i in 4:
			_px(img, 3 + i * 3, 6, Color("154360"))
	else:
		_rect(img, 2, 5, 12, 7, Color("2471a3"))
		_px(img, 10, 7, Color("fff"))
		_px(img, 11, 7, Color("1c2833"))
		_rect(img, 1, 8, 3, 3, Color("1a5276"))
		_rect(img, 12, 8, 3, 3, Color("1a5276"))
	return img

func _draw_pipe_chomp() -> Image:
	var img := _img(16, 24)
	_rect(img, 6, 0, 4, 10, Color("196f3d"))
	_rect(img, 1, 2, 7, 8, Color("27ae60"))
	_rect(img, 8, 2, 7, 8, Color("1e8449"))
	_rect(img, 3, 4, 4, 3, Color("922b21"))
	_rect(img, 9, 4, 4, 3, Color("922b21"))
	_rect(img, 4, 12, 8, 10, Color("145a32"))
	return img

func _draw_sky_rider() -> Image:
	var img := _img(48, 24)
	_rect(img, 8, 10, 32, 10, Color("d6eaf8"))
	_rect(img, 4, 14, 40, 6, Color("aed6f1"))
	_rect(img, 14, 6, 20, 8, Color("ebf5fb"))
	_rect(img, 18, 4, 12, 6, Color("5dade2"))
	_px(img, 22, 6, Color("fff"))
	_px(img, 26, 6, Color("fff"))
	return img

func _draw_duke_flame() -> Image:
	var img := _img(18, 10)
	_rect(img, 0, 2, 14, 6, Color("e74c3c"))
	_rect(img, 10, 1, 8, 8, Color("f5b041"))
	_px(img, 3, 4, Color("f9ca24"))
	return img

func _draw_firework() -> Image:
	var img := _img(12, 12)
	_px(img, 6, 6, Color("f9ca24"))
	var offs := [[0, -4], [3, -3], [4, 0], [3, 3], [0, 4], [-3, 3], [-4, 0], [-3, -3]]
	for i in offs.size():
		var o: Array = offs[i]
		_px(img, 6 + int(o[0]), 6 + int(o[1]), Color("e74c3c") if i % 2 == 0 else Color("3498db"))
	return img

func _draw_berry() -> Image:
	var img := _img(14, 14)
	_rect(img, 3, 4, 8, 8, Color("e74c3c"))
	_px(img, 6, 2, Color("27ae60"))
	_px(img, 7, 3, Color("2ecc71"))
	return img

func _draw_ember() -> Image:
	var img := _img(14, 14)
	_rect(img, 4, 3, 6, 8, Color("e76f51"))
	_px(img, 5, 2, Color("f4a261"))
	_px(img, 8, 5, Color("f9ca24"))
	return img

func _draw_star() -> Image:
	var img := _img(16, 16)
	var c := Color("f1c40f")
	for p in [Vector2i(8, 2), Vector2i(5, 6), Vector2i(11, 6), Vector2i(3, 11), Vector2i(13, 11), Vector2i(8, 13)]:
		_rect(img, p.x - 1, p.y - 1, 3, 3, c)
	_rect(img, 7, 6, 2, 6, c)
	return img

func _draw_one_up() -> Image:
	var img := _img(14, 14)
	_rect(img, 2, 5, 10, 6, Color("27ae60"))
	_px(img, 6, 3, Color("2ecc71"))
	_rect(img, 5, 7, 4, 2, Color("1e8449"))
	return img

func _draw_browncap() -> Image:
	var img := _img(16, 16)
	_rect(img, 2, 6, 12, 8, Color("8d6e63"))
	_rect(img, 3, 4, 10, 4, Color("6d4c41"))
	_px(img, 9, 7, Color("fff3e0"))
	_px(img, 10, 7, Color("264653"))
	_px(img, 5, 9, Color("5d4037"))
	return img

func _draw_shellbug(shell: bool) -> Image:
	var img := _img(16, 14)
	if shell:
		_rect(img, 1, 4, 14, 8, Color("1e8449"))
		for i in 4:
			_px(img, 3 + i * 3, 6, Color("2f6f4e"))
	else:
		_rect(img, 2, 5, 12, 7, Color("3d8b6e"))
		_px(img, 10, 7, Color("fff"))
		_px(img, 11, 7, Color("264653"))
		_rect(img, 1, 8, 3, 3, Color("2f6f4e"))
		_rect(img, 12, 8, 3, 3, Color("2f6f4e"))
	return img

func _draw_cliffbug(_shell: bool) -> Image:
	var img := _img(16, 14)
	_rect(img, 2, 5, 12, 7, Color("c0392b"))
	_px(img, 10, 7, Color("fff"))
	_px(img, 11, 7, Color("264653"))
	_rect(img, 1, 8, 3, 3, Color("922b21"))
	_rect(img, 12, 8, 3, 3, Color("922b21"))
	return img

func _draw_ashbug(shell: bool) -> Image:
	var img := _img(16, 14)
	if shell:
		_rect(img, 1, 4, 14, 8, Color("566573"))
		for i in 4:
			_px(img, 3 + i * 3, 6, Color("2c3e50"))
	else:
		_rect(img, 2, 5, 12, 7, Color("7f8c8d"))
		_px(img, 10, 7, Color("fff"))
		_px(img, 11, 7, Color("1c2833"))
		_rect(img, 1, 8, 3, 3, Color("5d6d7e"))
		_rect(img, 12, 8, 3, 3, Color("5d6d7e"))
	return img

func _draw_needler() -> Image:
	var img := _img(16, 14)
	_rect(img, 2, 6, 12, 6, Color("e74c3c"))
	_px(img, 4, 4, Color("922b21"))
	_px(img, 8, 3, Color("922b21"))
	_px(img, 12, 4, Color("922b21"))
	_px(img, 10, 8, Color("fff"))
	return img

func _draw_needler_egg() -> Image:
	var img := _img(10, 10)
	_rect(img, 2, 2, 6, 6, Color("f5b7b1"))
	_px(img, 4, 4, Color("922b21"))
	return img

func _draw_cannon() -> Image:
	var img := _img(16, 18)
	_rect(img, 2, 6, 12, 12, Color("2c3e50"))
	_rect(img, 0, 8, 6, 6, Color("1c2833"))
	return img

func _draw_pipe_shot() -> Image:
	var img := _img(12, 10)
	_rect(img, 0, 2, 10, 6, Color("2c3e50"))
	_rect(img, 8, 1, 4, 8, Color("1c2833"))
	_px(img, 2, 4, Color("ecf0f1"))
	return img

func _draw_swimfin() -> Image:
	var img := _img(18, 12)
	_rect(img, 2, 3, 12, 6, Color("e67e22"))
	_rect(img, 12, 4, 5, 4, Color("d35400"))
	_px(img, 5, 5, Color("fff"))
	return img

func _draw_inkjet() -> Image:
	var img := _img(14, 18)
	_rect(img, 3, 2, 8, 8, Color("5dade2"))
	_rect(img, 4, 10, 2, 6, Color("2874a6"))
	_rect(img, 8, 10, 2, 6, Color("2874a6"))
	_px(img, 5, 5, Color("fff"))
	_px(img, 9, 5, Color("fff"))
	return img

func _draw_ember_blob() -> Image:
	var img := _img(14, 14)
	_rect(img, 3, 3, 8, 8, Color("e74c3c"))
	_rect(img, 5, 1, 4, 4, Color("f5b041"))
	return img

func _draw_toss_twin() -> Image:
	var img := _img(16, 20)
	_rect(img, 3, 6, 10, 12, Color("1abc9c"))
	_rect(img, 5, 2, 6, 6, Color("16a085"))
	_px(img, 7, 4, Color("fff"))
	_rect(img, 1, 14, 4, 4, Color("117a65"))
	_rect(img, 11, 14, 4, 4, Color("117a65"))
	return img

func _draw_hammer() -> Image:
	var img := _img(10, 10)
	_rect(img, 3, 0, 4, 7, Color("7f8c8d"))
	_rect(img, 1, 0, 8, 3, Color("566573"))
	return img

func _draw_wing() -> Image:
	var img := _img(18, 8)
	_rect(img, 0, 3, 8, 4, Color("d5f5e3"))
	_rect(img, 10, 3, 8, 4, Color("abebc6"))
	return img

func _draw_duke(final_boss: bool) -> Image:
	var img := _img(28, 32)
	var body := Color("5b2c6f") if final_boss else Color("7d3c98")
	_rect(img, 4, 10, 20, 18, body)
	_rect(img, 8, 4, 12, 8, body.lightened(0.1))
	_rect(img, 10, 0, 8, 6, Color("d5d8dc"))
	for i in 3:
		_px(img, 11 + i, 1, Color("566573"))
	_rect(img, 6, 14, 4, 4, Color("f5b041"))
	_rect(img, 18, 14, 4, 4, Color("f5b041"))
	return img

func _draw_plant() -> Image:
	var img := _img(16, 24)
	_rect(img, 6, 0, 4, 14, Color("27ae60"))
	_rect(img, 2, 4, 6, 8, Color("2ecc71"))
	_rect(img, 8, 4, 6, 8, Color("2ecc71"))
	_rect(img, 4, 14, 8, 8, Color("1f7a6a"))
	return img

func _draw_cloud() -> Image:
	var img := _img(48, 24)
	_rect(img, 8, 10, 32, 10, Color(1, 1, 1, 0.85))
	_rect(img, 4, 14, 40, 6, Color(1, 1, 1, 0.75))
	_rect(img, 14, 6, 20, 8, Color(1, 1, 1, 0.9))
	return img

func _draw_spike() -> Image:
	var img := _img(10, 12)
	for row in 6:
		var w := 10 - row
		var x := row / 2
		_rect(img, x, row * 2, w, 2, Color("566573"))
	return img

func _draw_spring() -> Image:
	var img := _img(16, 12)
	_rect(img, 0, 8, 16, 4, Color("7f8c8d"))
	for i in 4:
		_rect(img, 2 + i * 3, 4 + (i % 2), 2, 4, Color("e8a838"))
	return img

func _draw_mover() -> Image:
	var img := _img(48, 12)
	_rect(img, 0, 4, 48, 8, Color("6d4c41"))
	_rect(img, 2, 2, 44, 2, Color("a67c52"))
	return img

func _draw_ember_shot() -> Image:
	var img := _img(8, 8)
	_rect(img, 1, 1, 6, 6, Color("e76f51"))
	_px(img, 3, 3, Color("f9ca24"))
	return img

func _draw_flag_pole() -> Image:
	var img := _img(4, 64)
	_rect(img, 1, 0, 2, 64, Color("ecf0f1"))
	return img

func _draw_flag_cloth() -> Image:
	var img := _img(20, 16)
	_rect(img, 0, 2, 18, 12, Color("e8a838"))
	_rect(img, 2, 4, 14, 8, Color("f1c40f"))
	return img

func _draw_axe() -> Image:
	var img := _img(14, 20)
	_rect(img, 6, 0, 2, 14, Color("bdc3c7"))
	_rect(img, 2, 2, 10, 6, Color("95a5a6"))
	return img

func _draw_fire_orb() -> Image:
	var img := _img(12, 12)
	_rect(img, 2, 2, 8, 8, Color("e74c3c"))
	_px(img, 5, 5, Color("f39c12"))
	return img

func _draw_lava() -> Image:
	var img := _img(16, 16)
	_rect(img, 0, 8, 16, 8, Color("c0392b"))
	_rect(img, 0, 10, 16, 4, Color("e74c3c"))
	_px(img, 3, 9, Color("f39c12"))
	_px(img, 11, 11, Color("f39c12"))
	return img

func _draw_water() -> Image:
	var img := _img(16, 16)
	_rect(img, 0, 0, 16, 16, Color("1a5276", 0.55))
	for x in range(0, 16, 4):
		_px(img, x, 4, Color("3498db", 0.4))
	return img

func _draw_hill(c: Color, w: int, h: int) -> Image:
	var img := _img(w, h)
	for x in w:
		var peak := int(sin(float(x) / w * PI) * (h - 8)) + (h - 12)
		for y in range(peak, h):
			_px(img, x, y, c)
	return img

func _draw_para_cloud() -> Image:
	return _draw_cloud()

func _draw_wave() -> Image:
	var img := _img(128, 32)
	for x in 128:
		var y := int(16 + sin(float(x) / 12.0) * 6)
		_rect(img, x, y, 1, 32 - y, Color("154360", 0.5))
	return img

func _draw_castle_sil() -> Image:
	var img := _img(96, 64)
	_rect(img, 20, 20, 56, 44, Color("2c1e3a"))
	_rect(img, 32, 8, 8, 16, Color("1a1423"))
	_rect(img, 56, 8, 8, 16, Color("1a1423"))
	return img

func _draw_smoke() -> Image:
	var img := _img(64, 32)
	_rect(img, 10, 16, 20, 12, Color(0.3, 0.25, 0.35, 0.35))
	_rect(img, 30, 12, 24, 16, Color(0.35, 0.3, 0.4, 0.3))
	return img

func _draw_under_bg() -> Image:
	var img := _img(128, 64)
	_rect(img, 0, 0, 128, 64, Color("0d1117"))
	for i in 20:
		_px(img, (i * 7) % 128, (i * 11) % 64, Color("1b263b"))
	return img

func _draw_under_stal() -> Image:
	var img := _img(64, 48)
	for i in 5:
		_rect(img, 4 + i * 12, 0, 6, 16 + i * 2, Color("2c3e50"))
	return img

func _draw_cap(form: String, frame: int, jump: bool) -> Image:
	var tall := form != "small"
	var h := 28 if tall else 16
	var img := _img(16, h + 8)
	var body_c := Color("e9c46a")
	var hat_c := Color("2a9d8f")
	if form == "fire":
		body_c = Color("e76f51")
		hat_c = Color("264653")
	elif form == "small":
		body_c = Color("f4a261")
	var body_y := 8 if tall else 14
	if jump:
		body_y -= 2
	_rect(img, 4, body_y, 8, h - 6 if tall else 10, body_c)
	_rect(img, 3, body_y - 6, 10, 6, hat_c)
	if frame == 1 and not jump:
		_px(img, 2, body_y + 4, body_c.darkened(0.1))
		_px(img, 13, body_y + 4, body_c.darkened(0.1))
	_px(img, 10, body_y + 2, Color("264653"))
	return img
