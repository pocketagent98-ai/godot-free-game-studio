extends Node
## Audio — bus setup + procedurally generated SFX so the game ships silent-asset-free.
## Replace the generated tones with real samples later; the API stays the same.

var _players: Dictionary = {}
var _music: AudioStreamPlayer

func _ready() -> void:
	_ensure_buses()
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_apply_settings()

func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)

func _apply_settings() -> void:
	var s: Dictionary = SaveManager.get_value("settings", {})
	set_bus_volume("Music", float(s.get("music", 0.7)))
	set_bus_volume("SFX", float(s.get("sfx", 0.9)))

func set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))
		AudioServer.set_bus_mute(idx, linear <= 0.001)

## Simple procedural blip. name is a logical sound id.
func play(name: String, pitch: float = 1.0) -> void:
	var stream := _tone_for(name)
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = stream
	p.pitch_scale = pitch
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func _tone_for(name: String) -> AudioStream:
	var freq := 440.0
	var dur := 0.08
	match name:
		"ui": freq = 660.0; dur = 0.05
		"countdown": freq = 520.0; dur = 0.18
		"go": freq = 880.0; dur = 0.30
		"checkpoint": freq = 720.0; dur = 0.12
		"finish": freq = 980.0; dur = 0.45
		"reward": freq = 1040.0; dur = 0.35
		"boost": freq = 300.0; dur = 0.25
		"crash": freq = 150.0; dur = 0.20
		_: freq = 440.0
	return _make_tone(freq, dur)

func _make_tone(freq: float, dur: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / float(rate)
		var env := 1.0 - (float(i) / float(count))
		var sample := sin(TAU * freq * t) * env * 0.35
		var v := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

func play_music(stream: AudioStream) -> void:
	if _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	_music.play()

func stop_music() -> void:
	_music.stop()
