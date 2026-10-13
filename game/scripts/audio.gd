extends Node
signal changed
var music: AudioStreamPlayer

func _ready() -> void:
	for bus_name in ["Music","SFX"]:
		if AudioServer.get_bus_index(bus_name)<0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
	music = AudioStreamPlayer.new()
	music.name = "DungeonMusic"
	music.bus = "Music"
	music.volume_db = -14
	var stream: AudioStreamOggVorbis = load("res://assets/dungeon_music.ogg")
	stream.loop = true
	music.stream = stream
	add_child(music)

func start() -> void:
	if not music.playing:
		music.play()

func muted(bus_name: String) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus_name))

func toggle(bus_name: String) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(index,not AudioServer.is_bus_mute(index))
	changed.emit()
