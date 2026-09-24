class_name Bomb
extends Node2D
## 抛出的炸弹：沿抛物线飞向落点，落点显示闪烁的红色预警圈，落地后爆炸（只伤害玩家）。

const RING_TEXTURE := preload("res://assets/sprites/bomb_ring.png")
## 预警圈贴图的半径（像素）
const RING_RADIUS := 28.0

@export var flight_time := 0.9
@export var radius := 28.0
@export var damage := 1
@export var arc_height := 40.0

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _t := 0.0
var _ring: Sprite2D

@onready var sprite: Sprite2D = $Sprite2D


func setup(from: Vector2, to: Vector2) -> void:
	_from = from
	_to = to
	position = from


func _ready() -> void:
	BlobShadow.add_to(self, 0.6)
	_ring = Sprite2D.new()
	_ring.texture = RING_TEXTURE
	_ring.scale = Vector2.ONE * radius / RING_RADIUS
	_ring.top_level = true # 预警圈固定在落点，不跟着炸弹飞
	_ring.material = preload("res://common/unshaded.tres") # 不受光照影响，暗处也看得清
	add_child(_ring)
	_ring.global_position = _to


func _process(delta: float) -> void:
	_t = minf(_t + delta / flight_time, 1.0)
	position = _from.lerp(_to, _t)
	sprite.position.y = -8.0 - sin(_t * PI) * arc_height
	sprite.rotation += delta * 10.0
	_ring.modulate.a = 0.8 + 0.2 * sin(_t * 30.0) # 闪烁提醒
	if _t >= 1.0:
		Explosion.spawn(get_parent(), _to, radius, damage, Bullet.Team.ENEMY)
		queue_free()

