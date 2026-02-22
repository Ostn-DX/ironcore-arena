extends Node
class_name AudioManager
## AudioManager — handles all game audio (SFX, music, UI sounds).
## Provides categorized sound playback with volume control.

# Audio buses
const BUS_MASTER: String = "Master"
const BUS_SFX: String = "SFX"
const BUS_MUSIC: String = "Music"
const BUS_UI: String = "UI"

# Sound effect categories
enum SoundCategory { WEAPON, EXPLOSION, UI, AMBIENT, VOICE }

# Sound effect library
var sound_library: Dictionary = {}

# Audio players pool
var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer = null
var ui_player: AudioStreamPlayer = null

# Settings
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.7
var ui_volume: float = 1.0

# Currently playing music
var current_music: String = ""


func _ready() -> void:
	_setup_audio_buses()
	_setup_players()
	_define_sound_library()


func _setup_audio_buses() -> void:
	## Ensure audio buses exist
	var buses: Array[String] = [BUS_MASTER, BUS_SFX, BUS_MUSIC, BUS_UI]
	
	for bus_name in buses:
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx == -1:
			var new_idx: int = AudioServer.add_bus(AudioServer.bus_count)
			AudioServer.set_bus_name(new_idx, bus_name)


func _setup_players() -> void:
	## Setup audio players
	# Music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = BUS_MUSIC
	add_child(music_player)
	
	# UI player
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UIPlayer"
	ui_player.bus = BUS_UI
	add_child(ui_player)
	
	# SFX pool (multiple players for overlapping sounds)
	for i in range(8):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = BUS_SFX
		add_child(player)
		sfx_players.append(player)


func _define_sound_library() -> void:
	## Define the sound effect library
	# Format: "sound_id" -> {"category": Category, "stream": AudioStream, "volume": 0.0-1.0}
	
	# Weapon sounds
	sound_library["weapon_fire"] = {
		"category": SoundCategory.WEAPON,
		"volume": 0.8
	}
	sound_library["weapon_hit"] = {
		"category": SoundCategory.WEAPON,
		"volume": 0.7
	}
	sound_library["weapon_reload"] = {
		"category": SoundCategory.WEAPON,
		"volume": 0.6
	}
	
	# Explosion sounds
	sound_library["explosion_small"] = {
		"category": SoundCategory.EXPLOSION,
		"volume": 0.9
	}
	sound_library["explosion_large"] = {
		"category": SoundCategory.EXPLOSION,
		"volume": 1.0
	}
	sound_library["bot_destroyed"] = {
		"category": SoundCategory.EXPLOSION,
		"volume": 1.0
	}
	
	# UI sounds
	sound_library["ui_click"] = {
		"category": SoundCategory.UI,
		"volume": 0.5
	}
	sound_library["ui_hover"] = {
		"category": SoundCategory.UI,
		"volume": 0.3
	}
	sound_library["ui_confirm"] = {
		"category": SoundCategory.UI,
		"volume": 0.6
	}
	sound_library["ui_cancel"] = {
		"category": SoundCategory.UI,
		"volume": 0.5
	}
	sound_library["ui_error"] = {
		"category": SoundCategory.UI,
		"volume": 0.6
	}
	
	# Ambient sounds
	sound_library["arena_ambient"] = {
		"category": SoundCategory.AMBIENT,
		"volume": 0.4
	}
	sound_library["menu_ambient"] = {
		"category": SoundCategory.AMBIENT,
		"volume": 0.3
	}
	
	# Voice/announcement sounds
	sound_library["announcer_victory"] = {
		"category": SoundCategory.VOICE,
		"volume": 0.9
	}
	sound_library["announcer_defeat"] = {
		"category": SoundCategory.VOICE,
		"volume": 0.9
	}
	sound_library["announcer_round_start"] = {
		"category": SoundCategory.VOICE,
		"volume": 0.8
	}
	sound_library["announcer_countdown"] = {
		"category": SoundCategory.VOICE,
		"volume": 0.8
	}


# ============================================================================
# SOUND PLAYBACK
# ============================================================================

func play_sfx(sound_id: String, pitch_variation: float = 0.0) -> void:
	## Play a sound effect
	if not sound_library.has(sound_id):
		push_warning("AudioManager: Sound not found: " + sound_id)
		return
	
	var sound_data: Dictionary = sound_library[sound_id]
	
	# Find available player
	var player: AudioStreamPlayer = _get_available_sfx_player()
	if not player:
		return  # All players busy
	
	# Load stream if not cached
	var stream: AudioStream = sound_data.get("stream")
	if not stream:
		stream = _load_stream(sound_id)
		sound_data["stream"] = stream
	
	if not stream:
		return
	
	# Setup and play
	player.stream = stream
	player.volume_db = linear_to_db(sound_data.get("volume", 1.0) * sfx_volume)
	
	if pitch_variation > 0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	else:
		player.pitch_scale = 1.0
	
	player.play()


func play_ui_sound(sound_id: String) -> void:
	## Play a UI sound
	if not sound_library.has(sound_id):
		return
	
	var sound_data: Dictionary = sound_library[sound_id]
	
	var stream: AudioStream = sound_data.get("stream")
	if not stream:
		stream = _load_stream(sound_id)
		sound_data["stream"] = stream
	
	if not stream:
		return
	
	ui_player.stream = stream
	ui_player.volume_db = linear_to_db(sound_data.get("volume", 1.0) * ui_volume)
	ui_player.play()


func play_music(music_id: String, fade_duration: float = 1.0) -> void:
	## Play background music
	if current_music == music_id and music_player.playing:
		return  # Already playing
	
	current_music = music_id
	
	var stream: AudioStream = _load_stream(music_id)
	if not stream:
		return
	
	# Fade out current if playing
	if music_player.playing:
		_fade_music_out(fade_duration / 2)
		await get_tree().create_timer(fade_duration / 2).timeout
	
	# Start new music
	music_player.stream = stream
	music_player.volume_db = linear_to_db(0.0)
	music_player.play()
	
	# Fade in
	_fade_music_in(fade_duration / 2)


func stop_music(fade_duration: float = 1.0) -> void:
	## Stop background music
	if not music_player.playing:
		return
	
	_fade_music_out(fade_duration)
	await get_tree().create_timer(fade_duration).timeout
	music_player.stop()
	current_music = ""


# ============================================================================
# UTILITY METHODS
# ============================================================================

func _get_available_sfx_player() -> AudioStreamPlayer:
	## Get an available SFX player
	for player in sfx_players:
		if not player.playing:
			return player
	return null


func _load_stream(sound_id: String) -> AudioStream:
	## Load an audio stream from file
	var path: String = "res://audio/sfx/%s.wav" % sound_id
	
	if not ResourceLoader.exists(path):
		# Try alternative formats
		path = "res://audio/sfx/%s.ogg" % sound_id
		if not ResourceLoader.exists(path):
			path = "res://audio/sfx/%s.mp3" % sound_id
			if not ResourceLoader.exists(path):
				push_warning("AudioManager: Could not find audio file for: " + sound_id)
				return null
	
	return load(path)


func _fade_music_in(duration: float) -> void:
	## Fade music volume in
	var tween: Tween = create_tween()
	tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), duration)


func _fade_music_out(duration: float) -> void:
	## Fade music volume out
	var tween: Tween = create_tween()
	tween.tween_property(music_player, "volume_db", linear_to_db(0.001), duration)


# ============================================================================
# VOLUME CONTROL
# ============================================================================

func set_master_volume(volume: float) -> void:
	## Set master volume (0.0 - 1.0)
	master_volume = clamp(volume, 0.0, 1.0)
	var db: float = linear_to_db(master_volume) if master_volume > 0.001 else -80.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MASTER), db)


func set_sfx_volume(volume: float) -> void:
	## Set SFX volume (0.0 - 1.0)
	sfx_volume = clamp(volume, 0.0, 1.0)
	var db: float = linear_to_db(sfx_volume) if sfx_volume > 0.001 else -80.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), db)


func set_music_volume(volume: float) -> void:
	## Set music volume (0.0 - 1.0)
	music_volume = clamp(volume, 0.0, 1.0)
	var db: float = linear_to_db(music_volume) if music_volume > 0.001 else -80.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), db)
	
	# Update playing music
	if music_player.playing:
		music_player.volume_db = db


func set_ui_volume(volume: float) -> void:
	## Set UI volume (0.0 - 1.0)
	ui_volume = clamp(volume, 0.0, 1.0)
	var db: float = linear_to_db(ui_volume) if ui_volume > 0.001 else -80.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_UI), db)


func mute_all(muted: bool) -> void:
	## Mute/unmute all audio
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_MASTER), muted)


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func play_weapon_fire() -> void:
	play_sfx("weapon_fire", 0.1)


func play_weapon_hit() -> void:
	play_sfx("weapon_hit")


func play_explosion(size: String = "small") -> void:
	match size:
		"small": play_sfx("explosion_small")
		"large": play_sfx("explosion_large")
		_: play_sfx("explosion_small")


func play_bot_destroyed() -> void:
	play_sfx("bot_destroyed")


func play_ui_click() -> void:
	play_ui_sound("ui_click")


func play_ui_hover() -> void:
	play_ui_sound("ui_hover")


func play_ui_confirm() -> void:
	play_ui_sound("ui_confirm")


func play_ui_cancel() -> void:
	play_ui_sound("ui_cancel")


func play_ui_error() -> void:
	play_ui_sound("ui_error")


func play_victory() -> void:
	play_sfx("announcer_victory")


func play_defeat() -> void:
	play_sfx("announcer_defeat")


func play_countdown() -> void:
	play_sfx("announcer_countdown")
