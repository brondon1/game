class_name DamageNumber
extends Label
## 飘字：敌人受伤时在头顶弹出伤害数字，往上飘并淡出。


static func spawn(parent: Node, pos: Vector2, amount: int, color := Color.WHITE) -> void:
	var number := DamageNumber.new()
	number.text = str(amount)
	number.add_theme_font_size_override("font_size", 8)
	number.add_theme_color_override("font_color", color)
	number.add_theme_color_override("font_outline_color", Color("181425"))
	number.add_theme_constant_override("outline_size", 3)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.size = Vector2(30, 12)
	number.position = pos + Vector2(-15 + randf_range(-4, 4), -24)
	number.z_index = 20
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.material = preload("res://common/unshaded.tres")
	parent.add_child(number)


func _ready() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - 12.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_delay(0.3)
	tween.chain().tween_callback(queue_free)
