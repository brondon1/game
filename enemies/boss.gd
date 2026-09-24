extends Enemy
## Boss：在 追击 → 环形弹幕 → 追击 → 扇形连射 之间循环。血量变化会通知 HUD 显示 Boss 血条。

enum Attack { CHASE, RING, FAN }

@export var ring_bullets := 16
@export var fan_bullets := 5

var _attack := Attack.CHASE
var _timer := 2.0
var _shots_left := 0
var _shot_timer := 0.0
var _next_special := Attack.RING


func _activate() -> void:
	super()
	Events.boss_health_changed.emit(hp, max_hp)


func take_damage(amount: int, direction := Vector2.ZERO) -> void:
	super(amount, direction * 0.2) # Boss 几乎不吃击退
	Events.boss_health_changed.emit(maxi(hp, 0), max_hp)


func _think(delta: float) -> Vector2:
	match _attack:
		Attack.CHASE:
			_timer -= delta
			if _timer <= 0.0:
				_start_attack(_next_special)
			return global_position.direction_to(player.global_position)
		Attack.RING:
			_update_shots(delta, 0.5, _fire_ring)
		Attack.FAN:
			_update_shots(delta, 0.22, _fire_fan)
	return Vector2.ZERO


func _start_attack(attack: Attack) -> void:
	_attack = attack
	_shot_timer = 0.4 # 起手停顿
	match attack:
		Attack.RING:
			_shots_left = 3
			_next_special = Attack.FAN
		Attack.FAN:
			_shots_left = 6
			_next_special = Attack.RING


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
		_timer = randf_range(1.5, 2.5)


func _fire_ring() -> void:
	var offset := _shots_left * 0.2 # 每一圈错开一点角度
	for i in ring_bullets:
		shoot_bullet(TAU * i / ring_bullets + offset, 90.0)
	Events.screen_shake.emit(2.0)


func _fire_fan() -> void:
	var base := global_position.angle_to_point(player.global_position)
	for i in fan_bullets:
		shoot_bullet(base + lerpf(-0.5, 0.5, float(i) / (fan_bullets - 1)), 140.0)
