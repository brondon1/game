extends CanvasLayer
## 暂停菜单：Esc / P / 手柄 Start / 手机右上角的暂停按钮打开或关闭。可以调节音乐和音效音量。

@onready var resume_button: Button = %ResumeButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var controls: Label = %Controls


func _ready() -> void:
	hide()
	if TouchControls.active:
		controls.text = "左边拖动移动 · 右下按钮攻击、技能、换枪\n点小地图看大地图 · 右上角按钮暂停"
	resume_button.pressed.connect(_resume)
	main_menu_button.pressed.connect(_to_main_menu)
	music_slider.value = Sound.get_volume(&"Music")
	sfx_slider.value = Sound.get_volume(&"SFX")
	music_slider.value_changed.connect(func(v: float) -> void: Sound.set_volume(&"Music", v))
	sfx_slider.value_changed.connect(func(v: float) -> void:
		Sound.set_volume(&"SFX", v)
		Sound.play(Sound.COIN, 0.0, 0.0)) # 拖动时播放一下，方便试听


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible:
		_resume()
	elif not get_tree().paused: # 选 Buff 或结算时不能再暂停
		show()
		get_tree().paused = true
		resume_button.grab_focus()
	get_viewport().set_input_as_handled()


func _resume() -> void:
	Sound.save_settings()
	hide()
	get_tree().paused = false


func _to_main_menu() -> void:
	Sound.save_settings()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
