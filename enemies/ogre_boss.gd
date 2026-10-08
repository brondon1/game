extends Boss
## 食人魔：追击 → 跳砸（落点先出现红色预警圈，落地震出一圈冲击波子弹）→ 追击 → 蓄力冲撞（撞墙会晕一会儿）。
## 强化版：连跳两次，冲击波子弹更多，冲撞更快。

enum State { CHASE, LEAP_WINDUP, LEAP, CHARGE_WINDUP, CHARGE, STUNNED }

@export var leap_time := 0.65
@export var shockwave_bullets := 12
@export var charge_speed := 170.0
@export var stun_time := 1.2

var _state := State.CHASE
var _timer := 2.0
var _next_leap := true
var _leaps_left := 0
var _leap_from := Vector2.ZERO
var _leap_to := Vector2.ZERO
var _ring: Sprite2D
var _charge_dir := Vector2.ZERO
var _walk_speed := 0.0


func _ready() -> void:
	super()
	_walk_speed = speed
	if enraged:
		shockwave_bullets += 6
		charge_speed += 40.0


func _think(delta: float) -> Vector2:
	_timer -= delta
	match _state:
		State.CHASE:
			if _timer <= 0.0:
				if _next_leap:
					_leaps_left = 2 if enraged else 1
					_start_leap_windup()
				else:
					_state = State.CHARGE_WINDUP
					_timer = 0.6
				_next_leap = not _next_leap
			return chase_direction()
		State.LEAP_WINDUP:
			sprite.position.x = sin(_timer * 60.0) # 蓄力时抖动
			if _timer <= 0.0:
				sprite.position.x = 0.0
				_state = State.LEAP
				_timer = leap_time
				_leap_from = global_position
				collision_layer = 0 # 在空中打不到
				Sound.play(Sound.THROW, 0.0, 0.0)
			return Vector2.ZERO
		State.LEAP:
			var t := 1.0 - maxf(_timer, 0.0) / leap_time
			global_position = _leap_from.lerp(_leap_to, t)
			sprite.position.y = _sprite_base_y - sin(t * PI) * 40.0
			if _timer <= 0.0:
				_land()
			return Vector2.ZERO
		State.CHARGE_WINDUP:
			sprite.position.x = sin(_timer * 60.0)
			sprite.self_modulate = Color(1, 0.6, 0.6)
			if _timer <= 0.0:
				sprite.position.x = 0.0
				sprite.self_modulate = Color.WHITE
				_state = State.CHARGE
				_timer = 1.1
				_charge_dir = global_position.direction_to(player.global_position)
				speed = charge_speed
				contact_damage = 2
			return Vector2.ZERO
		State.CHARGE:
			if _hit_wall():
				_end_charge(true)
				return Vector2.ZERO
			if _timer <= 0.0:
				_end_charge(false)
			return _charge_dir
		State.STUNNED:
			sprite.rotation = sin(_timer * 30.0) * 0.08
			if _timer <= 0.0:
				sprite.rotation = 0.0
				_state = State.CHASE
				_timer = randf_range(1.2, 2.0)
			return Vector2.ZERO
	return Vector2.ZERO


func _start_leap_windup() -> void:
	_state = State.LEAP_WINDUP
	_timer = 0.5
	_leap_to = player.global_position
	_ring = warning_ring(_leap_to, 30.0)


## 落地：震屏、冲击波子弹，正好砸在玩家身上还要额外受伤
func _land() -> void:
	sprite.position.y = _sprite_base_y
	collision_layer = Bullet.LAYER_ENEMY
	if is_instance_valid(_ring):
		_ring.queue_free()
	Events.screen_shake.emit(6.0)
	Sound.play(Sound.EXPLOSION, -4.0)
	HitEffect.spawn(get_parent(), global_position, Color("775c55"), 16, 1.2, true)
	bullet_ring(shockwave_bullets, 100.0, randf() * TAU)
	if global_position.distance_to(player.global_position) < 30.0:
		player.take_damage(1)
	_leaps_left -= 1
	if _leaps_left > 0:
		_start_leap_windup()
	else:
		_state = State.CHASE
		_timer = randf_range(1.5, 2.2)


## 冲撞时撞到的墙 / 石柱 / 木箱（撞到其他敌人不算）
func _hit_wall() -> bool:
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if not collider is Enemy and not collider is Player:
			if collider.has_method("take_damage"):
				collider.take_damage(6, _charge_dir) # 撞碎木箱
			return true
	return false


func _end_charge(hit_wall: bool) -> void:
	speed = _walk_speed
	contact_damage = 1
	if hit_wall:
		_state = State.STUNNED
		_timer = stun_time
		Events.screen_shake.emit(4.0)
		HitEffect.spawn(get_parent(), global_position + Vector2(0, -16), Color("facb3e"), 10, 0.8)
	else:
		_state = State.CHASE
		_timer = randf_range(1.2, 2.0)
