class_name LobbyDialog
extends CanvasLayer
## 大厅里的对话框：屏幕下方一个面板，左边头像，右边标题、正文和一排按钮。
## 和角色对话、走进传送门时都用它。打开时暂停游戏，关闭后恢复。

signal closed

@onready var portrait: TextureRect = %Portrait
@onready var title: Label = %Title
@onready var body: Label = %Body
@onready var buttons_box: HFlowContainer = %Buttons


func _ready() -> void:
	hide()


## buttons 是 [[按钮文字, 点击后调用的 Callable, 是否禁用（可省略）], ...]
func open(title_text: String, body_text: String, portrait_texture: Texture2D, buttons: Array) -> void:
	title.text = title_text
	body.text = body_text
	portrait.texture = portrait_texture
	portrait.visible = portrait_texture != null
	if portrait_texture:
		portrait.custom_minimum_size = portrait_texture.get_size() * 2.0 # 整数倍放大，像素不变形
	set_buttons(buttons)
	show()
	get_tree().paused = true


func set_body(text: String) -> void:
	body.text = text


func set_buttons(buttons: Array) -> void:
	for child in buttons_box.get_children():
		buttons_box.remove_child(child)
		child.queue_free()
	var first: Button = null
	for spec: Array in buttons:
		var button := Button.new()
		button.text = spec[0]
		button.disabled = spec.size() > 2 and spec[2]
		button.pressed.connect(spec[1])
		buttons_box.add_child(button)
		if first == null and not button.disabled:
			first = button
	if first:
		# 延迟到下一帧再给焦点；同一帧里按钮可能又被刷新掉了，所以先确认它还在
		(func() -> void:
			if is_instance_valid(first) and first.is_inside_tree():
				first.grab_focus()).call_deferred()


func close() -> void:
	hide()
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
