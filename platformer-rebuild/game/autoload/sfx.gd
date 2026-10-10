extends Node

var _players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func play(kind: String) -> void:
	var stream: AudioStreamWAV
	match kind:
		"jump":
			stream = _arpeggio([520, 780], 0.09)
		"stomp":
			stream = _noise_burst(120.0, 0.1)
		"coin":
			stream = _arpeggio([880, 1175, 880], 0.05)
		"power":
			stream = _arpeggio([440, 554, 659, 880], 0.08)
		"bump":
			stream = _arpeggio([280, 220], 0.06)
		"hurt":
			stream = _arpeggio([180, 140, 100], 0.12)
		"power_down":
			stream = _arpeggio([660, 440, 330, 220], 0.07)
		"pipe":
			stream = _arpeggio([300, 240, 180], 0.1)
		"clear":
			stream = _arpeggio([523, 659, 784, 1047], 0.1)
		"pause":
			stream = _arpeggio([400, 350], 0.05)
		_:
			stream = _tone(440.0, 0.08)
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	_players[0].stream = stream
	_players[0].play()

func _tone(freq: float, dur: float) -> AudioStreamWAV:
	return _wav_from_samples(_sample_sine(freq, dur))

func _arpeggio(freqs: Array, step: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	for f in freqs:
		data.append_array(_sample_sine(float(f), step))
	return _wav_from_samples(data)

func _noise_burst(base: float, dur: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var n := int(sample_rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / sample_rate
		var env := 1.0 - float(i) / n
		var s := int(sin(t * base * TAU + randf() * 0.5) * 0.35 * env * 32767.0)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return _wav_from_samples(data)

func _sample_sine(freq: float, dur: float) -> PackedByteArray:
	var sample_rate := 22050
	var n := int(sample_rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / sample_rate
		var env := 1.0 - (float(i) / n) * 0.35
		var s := int(sin(t * freq * TAU) * 0.32 * env * 32767.0)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	return data

func _wav_from_samples(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.mix_rate = 22050
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = false
	wav.data = data
	return wav
