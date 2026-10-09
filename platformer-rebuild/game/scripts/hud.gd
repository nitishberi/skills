extends CanvasLayer

@onready var label: Label = $Margin/Label

func _ready() -> void:
	RunState.changed.connect(_refresh)
	_refresh()

func _process(delta: float) -> void:
	# Stage controller also ticks; keep HUD live
	_refresh()

func _refresh() -> void:
	label.text = "PIPE HOP   SCORE %06d   COINS x%02d   %s   TIME %03d   LIVES x%d" % [
		RunState.score,
		RunState.coins,
		RunState.world_stage_label(),
		int(RunState.time_left),
		RunState.lives,
	]
