extends Node

var _players: Array[AudioStreamPlayer] = []
var _bus_ready := false

func _ready() -> void:
	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func play(kind: String) -> void:
	var freq := 440.0
	var dur := 0.08
	match kind:
		"jump":
			freq = 520.0
			dur = 0.07
		"stomp":
			freq = 180.0
			dur = 0.09
		"coin":
			freq = 880.0
			dur = 0.06
		"power":
			freq = 660.0
			dur = 0.12
		"bump":
			freq = 300.0
			dur = 0.05
		"hurt":
			freq = 140.0
			dur = 0.15
		"clear":
			freq = 740.0
			dur = 0.2
		"pause":
			freq = 400.0
			dur = 0.05
		_:
			pass
	var stream := _tone(freq, dur)
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	_players[0].stream = stream
	_players[0].play()

func _tone(freq: float, dur: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var n := int(sample_rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / sample_rate
		var env := 1.0 - (float(i) / n)
		var s := int(sin(t * freq * TAU) * 0.3 * env * 32767.0)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.mix_rate = sample_rate
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = false
	wav.data = data
	return wav
