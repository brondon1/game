class_name SlashEffect
extends Node2D
## 近战挥砍的刀光：一段扇形弧线，很快淡出后自动删除。

var radius := 28.0
var arc := PI * 2.0 / 3.0
var color := Color("f4f4f4")


static func spawn(parent: Node, pos: Vector2, angle: float, p_radius: float, p_arc: float, p_color: Color) -> void:
	var fx := SlashEffect.new()
	fx.position = pos
	fx.rotation = angle
	fx.radius = p_radius
	fx.arc = p_arc
	fx.color = p_color
	parent.add_child(fx)


func _ready() -> void:
	z_index = 5
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE * 1.15, 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, -arc / 2.0, arc / 2.0, 16, color, 3.0)
	draw_arc(Vector2.ZERO, radius - 4.0, -arc / 2.5, arc / 2.5, 12, Color(color, 0.5), 2.0)
