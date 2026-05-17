class_name AudioDirector
extends Node

const SAMPLE_RATE := 22050
const EVENTS := ["ui", "step", "blocked", "interact", "transition", "success"]
const STORY_MUSIC := {
	"01-illiterate": {
		"mud_road": "res://assets/audio/generated/music/01-illiterate/MUS-01-001.mp3",
		"camp": "res://assets/audio/generated/music/01-illiterate/MUS-01-001.mp3",
		"chase": "res://assets/audio/generated/music/01-illiterate/MUS-01-001.mp3",
		"station": "res://assets/audio/generated/music/01-illiterate/MUS-01-001.mp3",
	}
}
const STORY_VOICES := {
	"01-illiterate": [
		{
			"line_id": "DLG-01-SAMPLE-JZX",
			"match": "……这是哪？",
			"path": "res://assets/audio/generated/voices/01-illiterate/DLG-01-SAMPLE-JZX.mp3",
		},
		{
			"line_id": "DLG-01-SAMPLE-XY",
			"match": "□□？□□□！",
			"path": "res://assets/audio/generated/voices/01-illiterate/DLG-01-SAMPLE-XY.mp3",
		},
		{
			"line_id": "DLG-01-SAMPLE-XL",
			"match": "拿着那支笔还敢站在路中间。",
			"path": "res://assets/audio/generated/voices/01-illiterate/DLG-01-SAMPLE-XL.mp3",
		},
	]
}

var streams := {}
var players := {}
var story_music_player: AudioStreamPlayer
var story_voice_player: AudioStreamPlayer
var story_music_streams := {}
var story_voice_streams := {}
var current_story_music_key := ""
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

	story_music_player = AudioStreamPlayer.new()
	story_music_player.name = "AudioStoryMusic"
	story_music_player.volume_db = -13.0
	add_child(story_music_player)

	story_voice_player = AudioStreamPlayer.new()
	story_voice_player.name = "AudioStoryVoice"
	story_voice_player.volume_db = -2.0
	add_child(story_voice_player)

	_load_story_audio()


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


func sync_story_context(scene_id: String, location_id: String) -> void:
	if not enabled or story_music_player == null:
		return
	var scene_music: Dictionary = STORY_MUSIC.get(scene_id, {})
	var path := str(scene_music.get(location_id, ""))
	if path.is_empty():
		_stop_story_music()
		return
	var key := "%s/%s" % [scene_id, location_id]
	if current_story_music_key == key and story_music_player.playing:
		return
	var stream: AudioStream = story_music_streams.get(path)
	if stream == null:
		_stop_story_music()
		return
	current_story_music_key = key
	story_music_player.stream = stream
	story_music_player.play()


func play_story_voice_for_text(scene_id: String, text: String) -> bool:
	if not enabled or story_voice_player == null or text.is_empty():
		return false
	for voice in STORY_VOICES.get(scene_id, []):
		var match_text := str(voice.get("match", ""))
		if match_text.is_empty() or not text.contains(match_text):
			continue
		var path := str(voice.get("path", ""))
		var stream: AudioStream = story_voice_streams.get(path)
		if stream == null:
			return false
		if story_voice_player.playing:
			story_voice_player.stop()
		story_voice_player.stream = stream
		story_voice_player.play()
		return true
	return false


func is_story_voice_playing() -> bool:
	return story_voice_player != null and story_voice_player.playing


func verify_streams() -> bool:
	_load_story_audio()
	for event_name in EVENTS:
		if not streams.has(event_name):
			return false
		var stream: AudioStreamWAV = streams[event_name]
		if stream == null or stream.data.is_empty():
			return false
	for scene_id in STORY_MUSIC.keys():
		var scene_music: Dictionary = STORY_MUSIC[scene_id]
		for location_id in scene_music.keys():
			var path := str(scene_music[location_id])
			if not story_music_streams.has(path):
				return false
	for scene_id in STORY_VOICES.keys():
		for voice in STORY_VOICES[scene_id]:
			var path := str(voice.get("path", ""))
			if not story_voice_streams.has(path):
				return false
	return true


func _play(event_name: String) -> void:
	if not enabled or not players.has(event_name):
		return
	var player: AudioStreamPlayer = players[event_name]
	if player.playing:
		player.stop()
	player.play()


func _load_story_audio() -> void:
	for scene_id in STORY_MUSIC.keys():
		var scene_music: Dictionary = STORY_MUSIC[scene_id]
		for location_id in scene_music.keys():
			_cache_audio_stream(str(scene_music[location_id]), story_music_streams)
	for scene_id in STORY_VOICES.keys():
		for voice in STORY_VOICES[scene_id]:
			_cache_audio_stream(str(voice.get("path", "")), story_voice_streams)


func _cache_audio_stream(path: String, cache: Dictionary) -> void:
	if path.is_empty() or cache.has(path):
		return
	if not FileAccess.file_exists(path):
		push_warning("Story audio missing: %s" % path)
		return
	if path.get_extension().to_lower() == "mp3":
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.is_empty():
			push_warning("Story audio empty: %s" % path)
			return
		var mp3_stream := AudioStreamMP3.new()
		mp3_stream.data = bytes
		if path.contains("/music/"):
			mp3_stream.loop = true
		cache[path] = mp3_stream
		return
	if ResourceLoader.exists(path):
		var resource := load(path)
		if resource is AudioStream:
			cache[path] = resource


func _stop_story_music() -> void:
	current_story_music_key = ""
	if story_music_player != null and story_music_player.playing:
		story_music_player.stop()


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
