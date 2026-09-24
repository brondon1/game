extends Control
## 主菜单。

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var record_label: Label = %RecordLabel


func _ready() -> void:
	start_button.pressed.connect(_start)
	quit_button.pressed.connect(get_tree().quit)
	quit_button.visible = not OS.has_feature("web") # 网页版不能退出
	if GameState.best_floor > 0:
		record_label.text = "最高纪录：第 %d 层 · 通关 %d 次" % [GameState.best_floor, GameState.wins]
	else:
		record_label.text = "准备好进入地牢了吗？"
	start_button.grab_focus()


func _start() -> void:
	GameState.new_run()
	get_tree().change_scene_to_file("res://dungeon/dungeon.tscn")
