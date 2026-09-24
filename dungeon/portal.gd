class_name Portal
extends Area2D
## 传送门：打败 Boss 后出现，玩家走进去就进入下一层。

signal player_entered

var _used := false
var _time := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.scale = Vector2.ZERO
	create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_time += delta
	sprite.frame = int(_time * 8.0) % 4 # 换帧转动，像素不会被旋转拉歪


func _on_body_entered(body: Node2D) -> void:
	if _used or not body is Player:
		return
	_used = true
	player_entered.emit()
