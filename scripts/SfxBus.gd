extends Node

const GameConfig = preload("res://scripts/GameConfig.gd")

var players := {}
var missing := []
var verified_events := []
var trigger_counts := {}
var impact_voices: Array[AudioStreamPlayer] = []
var impact_by_event: Dictionary = {}
var impact_voice_index := 0
var last_impact_audio_ms := -1000
var bgm_player: AudioStreamPlayer
var bgm_stream: AudioStream
var bgm_missing := false
var bgm_play_requested := false
var bgm_loaded := false
var music_level := 0.65
var sfx_level := 0.8
var shake_level := 0.8
var reduce_motion := false
const PREFERENCES_PATH := "user://scifi_preferences_v1.cfg"

func _load_preferences() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scifi-test="): return # Test runs never depend on player volume settings.
	var config := ConfigFile.new()
	if config.load(PREFERENCES_PATH) != OK: return
	music_level = clampf(float(config.get_value("sound","music",0.65)),0.0,1.0)
	sfx_level = clampf(float(config.get_value("sound","effects",0.8)),0.0,1.0)
	shake_level = clampf(float(config.get_value("display","shake",0.8)),0.0,1.0)
	reduce_motion = bool(config.get_value("display","reduce_motion",false))

func preferences() -> Dictionary:
	return {"music":music_level,"effects":sfx_level,"shake":shake_level,"reduce_motion":reduce_motion}

func set_preferences(value: Dictionary) -> void:
	music_level = clampf(float(value.get("music",music_level)),0.0,1.0)
	sfx_level = clampf(float(value.get("effects",sfx_level)),0.0,1.0)
	shake_level = clampf(float(value.get("shake",shake_level)),0.0,1.0)
	reduce_motion = bool(value.get("reduce_motion",reduce_motion))
	_apply_levels()
	var config := ConfigFile.new()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scifi-test="): return # Test UI must not touch real user preferences.
	config.set_value("sound","music",music_level)
	config.set_value("sound","effects",sfx_level)
	config.set_value("display","shake",shake_level)
	config.set_value("display","reduce_motion",reduce_motion)
	if config.save(PREFERENCES_PATH) != OK:
		push_warning("Unable to persist audio/display preferences")

func _apply_levels() -> void:
	if bgm_player != null: bgm_player.volume_db = linear_to_db(maxf(0.0001, music_level)) - 7.0 if music_level > 0 else -80.0
	for key in players:
		players[key].volume_db = linear_to_db(maxf(0.0001,sfx_level)) - 3.0 if sfx_level > 0 else -80.0
	for voice in impact_voices:
		voice.volume_db = linear_to_db(maxf(0.0001,sfx_level)) - 3.0 if sfx_level > 0 else -80.0


func _ready() -> void:
	_load_preferences()
	var is_headless := DisplayServer.get_name().to_lower().contains("headless")
	_load_bgm(is_headless)
	for event_name in GameConfig.SFX.keys():
		trigger_counts[event_name] = 0
		var path: String = GameConfig.SFX[event_name]
		if is_headless:
			if ResourceLoader.exists(path):
				verified_events.append(event_name)
			else:
				missing.append(path)
			continue
		var stream := load(path)
		if stream == null:
			missing.append(path)
			continue
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.bus = "Master"
		add_child(player)
		players[event_name] = player
		if event_name == "hit" or event_name.ends_with("_hit") or event_name in ["hit_heavy","hit_metal"]:
			impact_by_event[event_name] = [player]
			# Small fixed voice pool prevents rapid hits from continually cutting each other off.
			impact_voices.append(player)
			for index in range(2):
				var extra := AudioStreamPlayer.new()
				extra.stream = stream
				extra.bus = "Master"
				add_child(extra)
				impact_voices.append(extra)
				impact_by_event[event_name].append(extra)

	_apply_levels()

func _load_bgm(is_headless: bool) -> void:
	if ResourceLoader.exists(String(GameConfig.BGM["runtime_path"])):
		bgm_stream = load(String(GameConfig.BGM["runtime_path"]))
	bgm_loaded = bgm_stream != null
	bgm_missing = not bgm_loaded
	if bgm_stream is AudioStreamOggVorbis:
		bgm_stream.loop = true
	if not bgm_loaded or is_headless:
		return
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = bgm_stream
	bgm_player.bus = "Master"
	bgm_player.volume_db = -12.0
	add_child(bgm_player)

func start_bgm() -> void:
	bgm_play_requested = true
	if bgm_player != null and not bgm_player.playing:
		bgm_player.play()

func stop_bgm() -> void:
	bgm_play_requested = false
	if bgm_player != null:
		bgm_player.stop()

func play_event(event_name: String) -> void:
	if trigger_counts.has(event_name):
		trigger_counts[event_name] = int(trigger_counts[event_name]) + 1
	if not players.has(event_name):
		return
	if (event_name == "hit" or event_name.ends_with("_hit") or event_name in ["hit_heavy","hit_metal"]) and not impact_voices.is_empty():
		var now := Time.get_ticks_msec()
		if now - last_impact_audio_ms < 42: return
		last_impact_audio_ms = now
		var voices: Array = impact_by_event.get(event_name, [players[event_name]])
		var voice: AudioStreamPlayer = voices[impact_voice_index % voices.size()]
		voice.pitch_scale = [0.94, 1.04, 0.99][impact_voice_index % 3]
		voice.volume_db = linear_to_db(maxf(0.0001,sfx_level)) - 3.0 if sfx_level > 0 else -80.0
		impact_voice_index += 1
		voice.stop()
		voice.play()
		return
	var player: AudioStreamPlayer = players[event_name]
	player.stop()
	if event_name == "player_hurt": player.pitch_scale = 0.89
	elif event_name == "enemy_die": player.pitch_scale = 0.94
	player.play()

func loaded_events() -> Array:
	if players.is_empty():
		return verified_events
	return players.keys()

func triggered_events() -> Dictionary:
	return trigger_counts.duplicate(true)

func bgm_status() -> Dictionary:
	return {
		"source_input_path": String(GameConfig.BGM["source_input_path"]),
		"runtime_path": String(GameConfig.BGM["runtime_path"]),
		"stream_loaded": bgm_loaded,
		"stream_length_seconds": bgm_stream.get_length() if bgm_stream != null else 0.0,
		"play_requested": bgm_play_requested,
		"has_audio_player": bgm_player != null,
		"playing": bgm_player.playing if bgm_player != null else false,
		"loop_enabled": bgm_stream.loop if bgm_stream is AudioStreamOggVorbis else false,
		"display_server": DisplayServer.get_name(),
		"is_silent_placeholder": false,
		"replaced_previous_bgm": true
	}

func shutdown() -> void:
	stop_bgm()
	if bgm_player != null:
		bgm_player.stream = null
		bgm_player.queue_free()
		bgm_player = null
	for voice in impact_voices:
		if not players.values().has(voice):
			voice.stop()
			voice.stream = null
			voice.queue_free()
	impact_voices.clear()
	impact_by_event.clear()
	for event_name in players.keys():
		var player: AudioStreamPlayer = players[event_name]
		player.stop()
		player.stream = null
		player.queue_free()
	players.clear()
