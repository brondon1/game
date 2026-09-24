class_name SlashEffect
extends Node2D
## 刀光：3 帧像素月牙，朝挥砍方向；扇形接近一整圈时（元素新星、影袭）改用扩散的冲击波圆环。

const SLASH_TEXTURE := preload("res://assets/sprites/slash.png")
const RING_TEXTURE := preload("res://assets/sprites/ring.png")
## 贴图里月牙 / 圆环的半径（像素），用来按实际范围缩放
const SLASH_RADIUS := 22.0
const RING_RADIUS := 25.0

var radius := 28.0
var arc := PI * 2.0 / 3.0
var color := Color.WHITE


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
	var sprite := Sprite2D.new()
	sprite.material = preload("res://common/unshaded.tres")
	sprite.modulate = color
	var frames := 3
	if arc >= TAU * 0.7:
		sprite.texture = RING_TEXTURE
		frames = 4
		sprite.scale = Vector2.ONE * radius / RING_RADIUS
	else:
		sprite.texture = SLASH_TEXTURE
		# 贴图里的月牙大约 120°，按实际扇形角度拉伸
		var k := radius / SLASH_RADIUS
		sprite.scale = Vector2(k, k * clampf(arc / (TAU / 3.0), 0.45, 1.3))
	sprite.hframes = frames
	add_child(sprite)
	var tween := create_tween()
	tween.tween_method(func(f: float) -> void: sprite.frame = mini(int(f), frames - 1), 0.0, float(frames), 0.16)
	tween.tween_callback(queue_free)
