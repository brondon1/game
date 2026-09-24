class_name Bomb
extends Node2D
## 抛出的炸弹：沿抛物线飞向落点，落点显示越来越大的红色预警圈，落地后爆炸（只伤害玩家）。

@export var flight_time := 0.9
@export var radius := 28.0
@export var damage := 1
@export var arc_height := 40.0

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _t := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func setup(from: Vector2, to: Vector2) -> void:
	_from = from
	_to = to
	position = from


func _ready() -> void:
	BlobShadow.add_to(self, 0.6)


func _process(delta: float) -> void:
	_t = minf(_t + delta / flight_time, 1.0)
	position = _from.lerp(_to, _t)
	sprite.position.y = -8.0 - sin(_t * PI) * arc_height
	sprite.rotation += delta * 10.0
	queue_redraw()
	if _t >= 1.0:
		Explosion.spawn(get_parent(), _to, radius, damage, Bullet.Team.ENEMY)
		queue_free()


func _draw() -> void:
	var center := _to - position
	var pulse := 0.6 + 0.4 * sin(_t * 30.0)
	draw_circle(center, radius * _t, Color(0.9, 0.2, 0.25, 0.18 * pulse))
	draw_arc(center, radius, 0.0, TAU, 24, Color(0.95, 0.25, 0.3, 0.7 * pulse), 1.0)
