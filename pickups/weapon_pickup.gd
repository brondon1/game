class_name WeaponPickup
extends Area2D
## 地上的武器：玩家靠近时显示提示，按 E（interact）拾取。

@export var data: WeaponData:
	set(value):
		data = value
		if is_node_ready():
			_refresh()

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.hide()
	_refresh()
	# 上下浮动
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -3.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)


func _refresh() -> void:
	sprite.texture = data.texture if data else null
	if data:
		label.text = "[E] %s  能耗 %d" % [data.display_name, data.energy_cost]


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.add_nearby_pickup(self)
		label.show()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.remove_nearby_pickup(self)
		label.hide()
