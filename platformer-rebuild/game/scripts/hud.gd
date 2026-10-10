extends CanvasLayer

@onready var label: Label = $Margin/Label

func _ready() -> void:
	RunState.changed.connect(_refresh)
	_refresh()

func _process(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	label.text = "PIPE HOP 0.3.2   SCORE %06d   COINS x%02d   %s   TIME %03d   LIVES x%d" % [
		RunState.score,
		RunState.coins,
		RunState.world_stage_label(),
		int(RunState.time_left),
		RunState.lives,
	]
