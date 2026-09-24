class_name Door
extends StaticBody2D
## 房间门：战斗时关上（挡住玩家和子弹），清完怪后打开。

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.hide()
	collision_layer = 0


func set_closed(closed: bool) -> void:
	# 可能在物理回调里被调用，所以用 set_deferred 修改碰撞层
	set_deferred("collision_layer", Bullet.LAYER_WORLD if closed else 0)
	if closed:
		sprite.show()
		sprite.scale = Vector2(1, 0)
		create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.15)
	else:
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(1, 0), 0.15)
		tween.tween_callback(sprite.hide)
