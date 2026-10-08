extends Boss
## 僵尸王：慢慢追 → 螺旋弹幕 → 追 → 召唤小僵尸 → 追 → 喷出几轮扇形的绿色毒液弹，循环。
## 强化版：螺旋弹幕变成两条旋臂，一次召唤更多小僵尸。

enum State { CHASE, SPIRAL, SUMMON, VOMIT }

const MINION_SCENE := preload("res://enemies/mini_slime.tscn")
const VOMIT_COLOR := Color("97da3f")
## 场上最多同时有几只召唤出来的小僵尸
const MAX_MINIONS := 6

var _state := State.CHASE
var _timer := 2.0
var _shot_timer := 0.0
var _shots_left := 0
var _spiral_angle := 0.0
var _order: Array[State] = [State.SPIRAL, State.SUMMON, State.VOMIT]
var _next := 0
var _minions: Array[Enemy] = []


func _think(delta: float) -> Vector2:
	_timer -= delta
	match _state:
		State.CHASE:
			if _timer <= 0.0:
				_start(_order[_next])
				_next = (_next + 1) % _order.size()
			return chase_direction()
		State.SPIRAL:
			_shot_timer -= delta
			if _shot_timer <= 0.0:
				_shot_timer = 0.09
				_spiral_angle += 0.42
				var arms := 2 if enraged else 1
				for arm in arms:
					shoot_bullet(_spiral_angle + PI * arm, 85.0)
				Sound.play(Sound.ENEMY_SHOT, -14.0)
			if _timer <= 0.0:
				_back_to_chase()
		State.SUMMON:
			sprite.position.x = sin(_timer * 50.0) # 召唤前抖动
			if _timer <= 0.0:
				sprite.position.x = 0.0
				_summon()
				_back_to_chase()
		State.VOMIT:
			_shot_timer -= delta
			if _shot_timer <= 0.0 and _shots_left > 0:
				_shots_left -= 1
				_shot_timer = 0.35
				var base := global_position.angle_to_point(player.global_position)
				for i in 7:
					var bullet := shoot_bullet(base + lerpf(-0.6, 0.6, i / 6.0), 110.0)
					bullet.sprite.modulate = VOMIT_COLOR
				Sound.play(Sound.BOSS_SHOT, -4.0)
			if _shots_left <= 0 and _shot_timer <= 0.0:
				_back_to_chase()
	return Vector2.ZERO


func _start(state: State) -> void:
	_state = state
	match state:
		State.SPIRAL:
			_timer = 3.0
			_shot_timer = 0.3
		State.SUMMON:
			_timer = 0.8
		State.VOMIT:
			_shots_left = 4 if enraged else 3
			_shot_timer = 0.3


func _back_to_chase() -> void:
	_state = State.CHASE
	_timer = randf_range(1.5, 2.5)


func _summon() -> void:
	_minions = _minions.filter(func(m: Enemy) -> bool: return is_instance_valid(m) and not m.is_queued_for_deletion())
	var count := mini(4 if enraged else 3, MAX_MINIONS - _minions.size())
	for i in count:
		var offset := Vector2.from_angle(TAU * i / maxf(count, 1) + randf()) * 26.0
		_minions.append(spawn_minion(MINION_SCENE, global_position + offset))
	Sound.play(Sound.THROW, -2.0)
	HitEffect.spawn(get_parent(), global_position, VOMIT_COLOR, 12, 1.0, true)
