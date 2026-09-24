class_name Crate
extends StaticBody2D
## 木箱：挡路也挡子弹，被打几下就碎，有概率掉金币或能量。

const PICKUP_SCENE := preload("res://pickups/pickup.tscn")

@export var max_hp := 6
@export var coin_chance := 0.3
@export var energy_chance := 0.25

var _hp := 0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("breakables") # 近战武器靠这个分组找到能砍的东西
	_hp = max_hp


func take_damage(amount: int, _direction := Vector2.ZERO) -> void:
	if _hp <= 0:
		return
	_hp -= amount
	# 受击抖一下
	sprite.position.x = 1.5
	create_tween().tween_property(sprite, "position:x", 0.0, 0.1)
	if _hp <= 0:
		_break.call_deferred()


func _break() -> void:
	Sound.play(Sound.CRATE_BREAK, -2.0)
	HitEffect.spawn(get_parent(), global_position + Vector2(0, -6), Color("a7703c"), 10)
	if randf() < coin_chance:
		_drop(Pickup.Kind.COIN, 1)
	if randf() < energy_chance:
		_drop(Pickup.Kind.ENERGY, 5)
	queue_free()


func _drop(kind: Pickup.Kind, amount: int) -> void:
	var pickup: Pickup = PICKUP_SCENE.instantiate()
	pickup.kind = kind
	pickup.amount = amount
	pickup.position = position
	get_parent().add_child(pickup)
