class_name GameOver
extends CanvasLayer
## 结算界面：死亡或通关后显示本局数据和最高纪录。

@onready var title: Label = %Title
@onready var stats: Label = %Stats
@onready var retry_button: Button = %RetryButton
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	hide()
	retry_button.pressed.connect(_retry)
	main_menu_button.pressed.connect(_to_main_menu)


func open(won: bool) -> void:
	title.text = "通关！" if won else "你倒下了"
	title.modulate = Color("facb3e") if won else Color("da4e38")
	stats.text = "到达：第 %d 层\n击杀：%d\n金币：%d\n\n最高纪录：第 %d 层 · 通关 %d 次" % [
		GameState.current_floor, GameState.kills, GameState.coins, GameState.best_floor, GameState.wins]
	show()
	get_tree().paused = true
	retry_button.grab_focus()


func _retry() -> void:
	get_tree().paused = false
	GameState.new_run()
	get_tree().change_scene_to_file("res://dungeon/dungeon.tscn")


func _to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
