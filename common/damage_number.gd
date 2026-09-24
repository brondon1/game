class_name DamageNumber
extends Node2D
## 飘字：敌人受伤时在头顶弹出像素数字，往上飘并淡出。数字贴图 digits.png 是 0~9 横向排列。

const DIGITS := preload("res://assets/sprites/digits.png")
const DIGIT_WIDTH := 5
const SPACING := 4 # 相邻数字共用一列描边，看起来更紧凑


static func spawn(parent: Node, pos: Vector2, amount: int, color := Color.WHITE) -> void:
	var number := DamageNumber.new()
	var text := str(amount)
	var start_x := -(text.length() - 1) * SPACING / 2.0
	for i in text.length():
		var digit := Sprite2D.new()
		digit.texture = DIGITS
		digit.hframes = 10
		digit.frame = int(text[i])
		digit.position = Vector2(start_x + i * SPACING, 0)
		number.add_child(digit)
	number.modulate = color
	number.position = pos + Vector2(randf_range(-4, 4), -22)
	number.z_index = 20
	number.material = preload("res://common/unshaded.tres")
	for child in number.get_children():
		child.use_parent_material = true
	parent.add_child(number)


func _ready() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - 12.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_delay(0.3)
	tween.chain().tween_callback(queue_free)
