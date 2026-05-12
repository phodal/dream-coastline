class_name AudioDirector
extends Node

const SAMPLE_RATE := 22050
const EVENTS := ["ui", "step", "blocked", "interact", "transition", "success"]

var streams := {}
var players := {}
var enabled := true


func _init() -> void:
	streams = {
		"ui": _make_tone(880.0, 0.055, 0.20),
		"step": _make_tone(180.0, 0.045, 0.13),
		"blocked": _make_tone(90.0, 0.09, 0.22),
		"interact": _make_tone(660.0, 0.11, 0.18),
		"transition": _make_tone(330.0, 0.16, 0.18),
		"success": _make_tone(990.0, 0.18, 0.20),
	}


func _ready() -> void:
	for event_name in EVENTS:
		var player := AudioStreamPlayer.new()
		player.name = "Audio%s" % event_name.capitalize()
		player.stream = streams[event_name]
		add_child(player)
		players[event_name] = player


func play_ui() -> void:
	_play("ui")


func play_step() -> void:
	_play("step")


func play_blocked() -> void:
	_play("blocked")


func play_interact() -> void:
	_play("interact")


func play_transition() -> void:
	_play("transition")


func play_success() -> void:
	_play("success")


func verify_streams() -> bool:
	for event_name in EVENTS:
		if not streams.has(event_name):
			return false
		var stream: AudioStreamWAV = streams[event_name]
		if stream == null or stream.data.is_empty():
			return false
	return true


func _play(event_name: String) -> void:
	if not enabled or not players.has(event_name):
		return
	var player: AudioStreamPlayer = players[event_name]
	if player.playing:
		player.stop()
	player.play()


func _make_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var frame_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	for frame in range(frame_count):
		var t := float(frame) / float(SAMPLE_RATE)
		var fade_in := clampf(t / 0.012, 0.0, 1.0)
		var fade_out := clampf((duration - t) / 0.035, 0.0, 1.0)
		var envelope := minf(fade_in, fade_out)
		var sample := int(sin(TAU * frequency * t) * volume * envelope * 32767.0)
		if sample < 0:
			sample = 65536 + sample
		data[frame * 2] = sample & 0xff
		data[frame * 2 + 1] = (sample >> 8) & 0xff

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
