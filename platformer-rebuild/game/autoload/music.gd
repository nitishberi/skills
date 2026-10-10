extends Node

var _player: AudioStreamPlayer
var _theme := ""

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.volume_db = -10.0
	add_child(_player)

func play_theme(name: String) -> void:
	if name == _theme and _player.playing:
		return
	_theme = name
	_player.stream = _make_loop(name)
	_player.play()

func stop() -> void:
	_theme = ""
	_player.stop()

func _make_loop(name: String) -> AudioStreamWAV:
	var notes: PackedFloat32Array
	match name:
		"title":
			notes = PackedFloat32Array([523, 659, 784, 659, 523, 440, 523, 0])
		"overworld":
			notes = PackedFloat32Array([392, 440, 494, 523, 494, 440, 392, 349, 392, 440, 494, 587, 523, 494, 440, 0])
		"under":
			notes = PackedFloat32Array([220, 247, 262, 294, 262, 247, 220, 196, 220, 247, 262, 311, 294, 262, 247, 0])
		"water":
			notes = PackedFloat32Array([330, 349, 392, 440, 392, 349, 330, 294, 330, 349, 392, 440, 494, 440, 392, 0])
		"castle":
			notes = PackedFloat32Array([196, 196, 220, 247, 220, 196, 175, 196, 220, 247, 262, 247, 220, 196, 175, 0])
		_:
			notes = PackedFloat32Array([392, 440, 494, 523, 0])
	return _sequence_to_wav(notes, 0.18 if name == "castle" else 0.22)

func _sequence_to_wav(freqs: PackedFloat32Array, step: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var data := PackedByteArray()
	for f in freqs:
		if f <= 0.0:
			data.append_array(_silence(sample_rate, step * 0.35))
			continue
		data.append_array(_tone_bytes(sample_rate, f, step))
	var wav := AudioStreamWAV.new()
	wav.mix_rate = sample_rate
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.data = data
	return wav

func _silence(sr: int, dur: float) -> PackedByteArray:
	var n := int(sr * dur)
	var out := PackedByteArray()
	out.resize(n * 2)
	return out

func _tone_bytes(sr: int, freq: float, dur: float) -> PackedByteArray:
	var n := int(sr * dur)
	var out := PackedByteArray()
	out.resize(n * 2)
	for i in n:
		var t := float(i) / sr
		var env := 1.0
		if i < 80:
			env = float(i) / 80.0
		elif i > n - 120:
			env = float(n - i) / 120.0
		var s := int(sin(t * freq * TAU) * 0.22 * env * 32767.0)
		out[i * 2] = s & 0xFF
		out[i * 2 + 1] = (s >> 8) & 0xFF
	return out
