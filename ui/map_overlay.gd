class_name MapOverlay
extends CanvasLayer
## 全屏大地图：Tab / M 打开并暂停游戏，再按一次或按 Esc 关闭。
## 地图本身复用 Minimap 的绘制逻辑（开启 fit_all 全图模式）。

@onready var map: Minimap = %FullMap
@onready var title: Label = %MapTitle


func _ready() -> void:
	hide()


func setup(rooms: Dictionary, links: Array) -> void:
	map.setup(rooms, links)


func _unhandled_input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("map") or event.is_action_pressed("pause"):
			close()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("map") and not get_tree().paused:
		open()
		get_viewport().set_input_as_handled()


func open() -> void:
	title.text = "地图 · 第 %d 层" % GameState.current_floor
	show()
	get_tree().paused = true
	Sound.play(Sound.CLICK, -4.0, 0.0)


func close() -> void:
	hide()
	get_tree().paused = false
