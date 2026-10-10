extends RefCounted
## Exact SMB1 stage *types* per world (wiki table). Layouts are original Pipe Hop geometry.

const MAX_WORLDS := 8
const STAGES_PER_WORLD := 4

# Wiki: W3-2/W5-2/W6-2/W8-2/W8-3 are ground; only W1-2 and W4-2 underground;
# W2-2 and W7-2 underwater; W8-3 is ground (not athletic).
static func stage_kind(world: int, stage: int) -> String:
	if stage == 4:
		return "castle"
	if stage == 3:
		if world == 8:
			return "ground"
		return "athletic"
	if stage == 2:
		if world == 2 or world == 7:
			return "water"
		if world == 1 or world == 4:
			return "under"
		return "ground"
	return "ground"

static func music_theme(world: int, stage: int) -> String:
	match stage_kind(world, stage):
		"castle":
			return "castle"
		"water":
			return "water"
		"under":
			return "under"
		_:
			return "overworld"

static func apply_sky(world: int, stage: int) -> void:
	var kind := stage_kind(world, stage)
	match kind:
		"castle":
			RenderingServer.set_default_clear_color(Color("1a1423"))
		"water":
			RenderingServer.set_default_clear_color(Color("1a5276"))
		"under":
			RenderingServer.set_default_clear_color(Color("1b263b"))
		_:
			# Night W3/W6; snowy tint W5/W7; W8 approach dusk.
			if world == 3 or world == 6:
				RenderingServer.set_default_clear_color(Color("1c2833"))
			elif world == 5 or world == 7:
				RenderingServer.set_default_clear_color(Color("a8dadc"))
			elif world == 8:
				RenderingServer.set_default_clear_color(Color("5d6d7e"))
			else:
				RenderingServer.set_default_clear_color(Color("7ec8e3"))

static func is_handcrafted(world: int, stage: int) -> bool:
	return world <= 2

static func level_width_tiles(world: int, stage: int) -> int:
	# Bigger, denser courses than early Pipe Hop (still original layouts).
	var base := 120 + world * 10 + stage * 6
	match stage_kind(world, stage):
		"castle":
			return mini(base + 8, 160)
		"athletic":
			return base + 28
		"water":
			return base + 16
		"under":
			return base + 20
		_:
			return base

static func seed(world: int, stage: int, salt: int) -> int:
	return absi((world * 977 + stage * 131 + salt * 17) * 2654435761)
