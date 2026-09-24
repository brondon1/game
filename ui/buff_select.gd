class_name BuffSelect
extends CanvasLayer
## 每层通关后的强化三选一。打开时暂停游戏。

signal buff_chosen(id: String)

@onready var buttons_box: HBoxContainer = %Buttons


func _ready() -> void:
	hide()


func open(buffs: Array) -> void:
	for child in buttons_box.get_children():
		child.queue_free()
	var first: Button = null
	for buff: Dictionary in buffs:
		var button := Button.new()
		button.text = "%s\n\n%s" % [buff.name, buff.desc]
		button.custom_minimum_size = Vector2(120, 84)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_choose.bind(buff.id))
		buttons_box.add_child(button)
		if first == null:
			first = button
	show()
	get_tree().paused = true
	if first:
		first.grab_focus.call_deferred()


func _choose(id: String) -> void:
	hide()
	buff_chosen.emit(id)
