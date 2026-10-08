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
	var ch := GameState.character
	var upgrade_hint := "，回大厅找角色升级" if GameState.can_upgrade(ch) else ""
	stats.text = "到达：第 %d 层\n击杀：%d\n金币：%d\n本局经验：+%d（%s 现有 %d 经验%s）\n\n最高纪录：第 %d 层 · 通关 %d 次" % [
		GameState.current_floor, GameState.kills, GameState.coins, GameState.run_xp, ch.display_name,
		GameState.xp_of(ch), upgrade_hint, GameState.best_floor, GameState.wins]
	show()
	get_tree().paused = true
	retry_button.grab_focus()


func _retry() -> void:
	get_tree().paused = false
	GameState.start_run()
	get_tree().change_scene_to_file("res://dungeon/dungeon.tscn")


func _to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://lobby/lobby.tscn")
