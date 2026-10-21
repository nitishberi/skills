extends CanvasLayer

var _panel: ColorRect
var _label: Label
var _paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_panel = ColorRect.new()
	_panel.visible = false
	_panel.color = Color(0, 0, 0, 0.55)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = Label.new()
	_label.visible = false
	_label.text = "PAUSED\n\nPress Esc or P"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_label)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	_paused = not _paused
	get_tree().paused = _paused
	_panel.visible = _paused
	_label.visible = _paused
	Sfx.play("pause")
