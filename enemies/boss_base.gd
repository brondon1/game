class_name Boss
extends Enemy
## Boss 基类：出场时 HUD 显示名字和血条，几乎不吃击退。
## 后半程（第 4 层起）出现的是强化版（enraged），各个 Boss 自己决定强化成什么样。
## 新增 Boss：继承这个类写 _think()，做一个场景，加到 Room.BOSS_SCENES。

@export var boss_name := "Boss"

var enraged := false


func _ready() -> void:
	enraged = GameState.current_floor * 2 > GameState.FINAL_FLOOR
	super()


func _activate() -> void:
	super()
	Events.boss_appeared.emit(boss_name)
	Events.boss_health_changed.emit(hp, max_hp)


func take_damage(amount: int, direction := Vector2.ZERO) -> void:
	super(amount, direction * 0.2) # Boss 几乎不吃击退
	Events.boss_health_changed.emit(maxi(hp, 0), max_hp)


## 在地上放一个红色预警圈（和炸弹落点一样），返回它，用完自己 queue_free()。
func warning_ring(pos: Vector2, radius: float) -> Sprite2D:
	var ring := Sprite2D.new()
	ring.texture = Bomb.RING_TEXTURE
	ring.scale = Vector2.ONE * radius / Bomb.RING_RADIUS
	ring.top_level = true
	ring.material = preload("res://common/unshaded.tres")
	add_child(ring)
	ring.global_position = pos
	return ring


## 一圈子弹：count 颗，均匀分布，offset 是整体旋转的角度
func bullet_ring(count: int, bullet_speed: float, offset := 0.0) -> void:
	for i in count:
		shoot_bullet(TAU * i / count + offset, bullet_speed)
