extends RefCounted
## SMB1 stage *types* per world (ground / under / water / athletic / castle), original layouts.

const MAX_WORLDS := 8
const STAGES_PER_WORLD := 4

# SMB pattern: X-1 ground, X-2 under or water, X-3 athletic, X-4 castle.
# Worlds 2 and 7 use underwater on stage 2 (like SMB 2-2 and 7-2).
static func stage_kind(world: int, stage: int) -> String:
	if stage == 4:
		return "castle"
	if stage == 3:
		return "athletic"
	if stage == 2:
		if world == 2 or world == 7:
			return "water"
		return "under"
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
			if world == 3 or world == 6:
				RenderingServer.set_default_clear_color(Color("2c3e50"))
			elif world == 5 or world == 7:
				RenderingServer.set_default_clear_color(Color("a8dadc"))
			else:
				RenderingServer.set_default_clear_color(Color("7ec8e3"))

static func is_handcrafted(world: int, stage: int) -> bool:
	return world <= 2

static func level_width_tiles(world: int, stage: int) -> int:
	var base := 72 + world * 4 + stage * 3
	match stage_kind(world, stage):
		"castle":
			return mini(base, 78)
		"athletic":
			return base + 12
		"water":
			return base + 6
		"under":
			return base + 8
		_:
			return base

static func seed(world: int, stage: int, salt: int) -> int:
	return absi((world * 977 + stage * 131 + salt * 17) * 2654435761)
