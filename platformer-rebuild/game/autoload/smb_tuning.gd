extends Node
## NES Super Mario Bros.–style feel (clean-room; see replica/smb-mechanics.md).

const STAGE_TIME_DISPLAY := 400
const TIMER_UNITS_PER_SECOND := 2.5
const TIMER_HURRY_BELOW := 100

const WALK_MAX := 96.0
const RUN_MAX := 158.0
const GROUND_ACCEL := 680.0
const GROUND_DECEL := 520.0
const AIR_ACCEL := 400.0
const AIR_DECEL := 200.0

const GRAVITY := 1000.0
const MAX_FALL := 450.0
const JUMP_SMALL := -300.0
const JUMP_RUN_BONUS := -48.0
const JUMP_CUT := 0.5
const COYOTE := 0.09
const JUMP_BUFFER := 0.11

const STOMP_BOUNCE := 0.52
const HIT_IFRAMES := 2.0
const STAR_SECONDS := 10.0
const MAX_FIREBALLS := 2
const FIRE_COOLDOWN := 0.28

const HARD_ENEMY_SPEED_MUL := 1.45

func flagpole_bonus(touch_y: float, pole_top_y: float, pole_bottom_y: float) -> int:
	var h := pole_bottom_y - touch_y
	var span := maxf(1.0, pole_bottom_y - pole_top_y)
	var t := clampf(h / span, 0.0, 1.0)
	if t >= 0.92:
		return 5000
	if t >= 0.75:
		return 2000
	if t >= 0.55:
		return 800
	if t >= 0.35:
		return 400
	return 100
