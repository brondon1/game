extends Node
## 音效和背景音乐管理器。任何地方调用 Sound.play(Sound.XXX) 播放音效，Sound.play_music() 切换背景音乐。
## 音量设置（音乐 / 音效两条总线）保存在 user://settings.cfg。

const SHOOT := preload("res://assets/audio/shoot.wav")
const HIT := preload("res://assets/audio/hit.wav")
const DEFLECT := preload("res://assets/audio/deflect.wav")
const ENEMY_DIE := preload("res://assets/audio/enemy_die.wav")
const ENEMY_SHOT := preload("res://assets/audio/enemy_shot.wav")
const BOSS_SHOT := preload("res://assets/audio/boss_shot.wav")
const PLAYER_HURT := preload("res://assets/audio/player_hurt.wav")
const COIN := preload("res://assets/audio/coin.wav")
const ENERGY := preload("res://assets/audio/energy.wav")
const HEAL := preload("res://assets/audio/heal.wav")
const PICKUP_WEAPON := preload("res://assets/audio/pickup_weapon.wav")
const DOOR := preload("res://assets/audio/door.wav")
const PORTAL := preload("res://assets/audio/portal.wav")
const BUFF := preload("res://assets/audio/buff.wav")
const CLICK := preload("res://assets/audio/click.wav")
const VICTORY := preload("res://assets/audio/victory.wav")
const GAME_OVER := preload("res://assets/audio/game_over.wav")

const MUSIC_DUNGEON := preload("res://assets/audio/music_dungeon.wav")
const MUSIC_BOSS := preload("res://assets/audio/music_boss.wav")

const SETTINGS_PATH := "user://settings.cfg"
const VOICES := 16
## 同一个音效在这段时间（秒）内只播放一次，避免几十颗子弹同时命中时音量叠爆
const MIN_REPEAT_INTERVAL := 0.03

var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _last_played := {}
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # 暂停时菜单点击音效和音乐照常播放
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_voices.append(player)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	add_child(_music)
	_load_settings()
	# 所有按钮自动带点击音效
	get_tree().node_added.connect(_on_node_added)


## 播放一个音效。pitch_jitter 让音高随机浮动，重复的音效听起来不那么单调。
func play(stream: AudioStream, volume_db := 0.0, pitch_jitter := 0.08) -> void:
	if stream == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_played.get(stream, -1.0) < MIN_REPEAT_INTERVAL:
		return
	_last_played[stream] = now
	# 轮流使用播放器；都在忙时覆盖最早的那个
	var player := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()


## 切换背景音乐。正在播放同一首时不会从头开始。传 null 停止音乐。
func play_music(stream: AudioStream) -> void:
	if stream == null:
		_music.stop()
		return
	if _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	_music.play()


# ---------- 音量 ----------

## 音量是 0~1 的线性值
func get_volume(bus: StringName) -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus)))


func set_volume(bus: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(index, linear_to_db(linear))
	AudioServer.set_bus_mute(index, linear <= 0.001)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", get_volume(&"Music"))
	cfg.set_value("audio", "sfx", get_volume(&"SFX"))
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	set_volume(&"Music", cfg.get_value("audio", "music", 0.6))
	set_volume(&"SFX", cfg.get_value("audio", "sfx", 0.8))


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(func() -> void: play(CLICK, -4.0, 0.0))
