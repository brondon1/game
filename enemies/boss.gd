extends Boss
## 地牢恶魔：追击和特殊攻击交替，特殊攻击按顺序轮换。阶数越高，轮换里的招式越多、弹幕越密：
## - 0 阶：环形弹幕、扇形连射
## - 1 阶起：十字旋转弹幕（四条子弹流一边转一边射）
## - 2 阶起：分裂弹（大子弹飞一会儿炸成一圈小子弹）；环形弹幕变成内外两层
## - 3 阶：陨石雨（玩家周围一圈预警圈，随后炸开）

enum Attack { CHASE, RING, FAN, CROSS, SPLIT, METEOR }

@export var ring_bullets := 16
@export var fan_bullets := 5

var _attack := Attack.CHASE
var _timer := 2.0
var _shots_left := 0
var _shot_timer := 0.0
var _order: Array[Attack] = [Attack.RING, Attack.FAN]
var _next := 0
var _cross_angle := 0.0


func _ready() -> void:
	super()
	ring_bullets += 3 * tier
	fan_bullets += tier
	if tier >= 1:
		_order.append(Attack.CROSS)
	if tier >= 2:
		_order.append(Attack.SPLIT)
	if tier >= 3:
		_order.append(Attack.METEOR)


func _think(delta: float) -> Vector2:
	match _attack:
		Attack.CHASE:
			_timer -= delta
			if _timer <= 0.0:
				_start_attack(_order[_next])
				_next = (_next + 1) % _order.size()
			return chase_direction()
		Attack.RING:
			_update_shots(delta, 0.5, _fire_ring)
		Attack.FAN:
			_update_shots(delta, 0.22, _fire_fan)
		Attack.CROSS:
			_update_shots(delta, 0.1, _fire_cross)
		Attack.SPLIT:
			_update_shots(delta, 0.45, _fire_split)
		Attack.METEOR:
			_update_shots(delta, 0.35, _fire_meteor)
	return Vector2.ZERO


func _start_attack(attack: Attack) -> void:
	_attack = attack
	_shot_timer = 0.4 # 起手停顿
	match attack:
		Attack.RING:
			_shots_left = 3 + (1 if tier >= 1 else 0)
		Attack.FAN:
			_shots_left = 6 + tier
		Attack.CROSS:
			_shots_left = 24
			_cross_angle = randf() * TAU
		Attack.SPLIT:
			_shots_left = 3
		Attack.METEOR:
			_shots_left = 3


func _update_shots(delta: float, interval: float, fire: Callable) -> void:
	_shot_timer -= delta
	if _shot_timer > 0.0:
		return
	if _shots_left > 0:
		_shots_left -= 1
		_shot_timer = interval
		fire.call()
	else:
		_attack = Attack.CHASE
		_timer = randf_range(1.5, 2.5) - 0.2 * tier # 阶数越高，喘气的时间越短


func _fire_ring() -> void:
	bullet_ring(ring_bullets, 90.0, _shots_left * 0.2) # 每一圈错开一点角度
	if tier >= 2: # 内层一圈慢一些、错开半格，形成两层
		bullet_ring(ring_bullets, 60.0, _shots_left * 0.2 + PI / ring_bullets)
	Sound.play(Sound.BOSS_SHOT)
	Events.screen_shake.emit(2.0)


func _fire_fan() -> void:
	var base := global_position.angle_to_point(player.global_position)
	for i in fan_bullets:
		shoot_bullet(base + lerpf(-0.5, 0.5, float(i) / (fan_bullets - 1)), 140.0)
	Sound.play(Sound.BOSS_SHOT, -4.0)


## 十字旋转：四条子弹流，3 阶时六条
func _fire_cross() -> void:
	var arms := 6 if tier >= 3 else 4
	_cross_angle += 0.16
	for i in arms:
		shoot_bullet(_cross_angle + TAU * i / arms, 100.0)
	Sound.play(Sound.ENEMY_SHOT, -14.0)


func _fire_split() -> void:
	var base := global_position.angle_to_point(player.global_position)
	split_bullet(base, 80.0, 0.8, 8 + 2 * tier, 85.0)
	Sound.play(Sound.BOSS_SHOT, -2.0)


## 陨石雨：玩家脚下一个、周围再撒几个
func _fire_meteor() -> void:
	delayed_burst(player.global_position, 0.8, 10, 70.0)
	for i in 3:
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(30.0, 70.0)
		delayed_burst(player.global_position + offset, 0.8 + 0.1 * i, 8, 60.0)
	Sound.play(Sound.THROW, -4.0)
