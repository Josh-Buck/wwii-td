extends Node

# Stub for v1 M0. Music + SFX wiring lands in M2.

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Music"
	add_child(music_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = &"SFX"
	add_child(sfx_player)

func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	sfx_player.stream = stream
	sfx_player.play()

func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	music_player.stop()
