extends CanvasLayer
## 暂停菜单：Esc / P / 手柄 Start 打开或关闭。

@onready var resume_button: Button = %ResumeButton
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	hide()
	resume_button.pressed.connect(_resume)
	main_menu_button.pressed.connect(_to_main_menu)


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
	hide()
	get_tree().paused = false


func _to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
