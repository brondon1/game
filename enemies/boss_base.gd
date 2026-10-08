class_name Boss
extends Enemy
## Boss 基类：出场时 HUD 显示名字和血条，几乎不吃击退。
## tier 是 Boss 的阶数（0～3，每三层一章升一阶）：各个 Boss 按阶数解锁新技能、加密弹幕。
## 新增 Boss：继承这个类写 _think()，做一个场景，加到 Room.BOSS_SCENES。

const TIER_NAMES: Array[String] = ["", "·强化", "·狂暴", "·虚空"]
## 会分裂的大子弹和毒液弹的颜色
const SPLIT_COLOR := Color("f78697")

@export var boss_name := "Boss"

var tier := 0


func _ready() -> void:
	tier = GameState.boss_tier()
	super()


func _activate() -> void:
	super()
	Events.boss_appeared.emit(boss_name + TIER_NAMES[tier])
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


## 从任意位置射出一颗子弹（落点爆开、大子弹分裂用）
func shoot_from(pos: Vector2, angle: float, bullet_speed: float) -> Bullet:
	var bullet := shoot_bullet(angle, bullet_speed)
	bullet.global_position = pos
	return bullet


func ring_from(pos: Vector2, count: int, bullet_speed: float, offset := 0.0, color := Color.WHITE) -> void:
	for i in count:
		shoot_from(pos, TAU * i / count + offset, bullet_speed).sprite.modulate = color


## 落点轰炸：先在 pos 出现预警圈，delay 秒后在那里炸开一圈子弹（Boss 先死了就不炸）
func delayed_burst(pos: Vector2, delay: float, count: int, bullet_speed: float, color := Color.WHITE) -> void:
	var ring := warning_ring(pos, 14.0)
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		ring.queue_free()
		ring_from(pos, count, bullet_speed, randf() * TAU, color)
		HitEffect.spawn(get_parent(), pos, color if color != Color.WHITE else Color("da4e38"), 6, 0.6)
		Sound.play(Sound.ENEMY_SHOT, -6.0))


## 会分裂的大子弹：飞 delay 秒后炸成一圈小子弹（中途撞墙或打中玩家就不分裂了）
func split_bullet(angle: float, bullet_speed: float, delay: float, count: int, child_speed: float) -> void:
	var bullet := shoot_bullet(angle, bullet_speed)
	bullet.scale = Vector2.ONE * 1.8
	bullet.sprite.modulate = SPLIT_COLOR
	var ref: WeakRef = weakref(bullet) # 子弹可能先撞墙没了，不能直接抓着它
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		var b: Bullet = ref.get_ref()
		if b and not b.is_queued_for_deletion():
			ring_from(b.global_position, count, child_speed, randf() * TAU, SPLIT_COLOR)
			b.queue_free())
