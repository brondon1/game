extends Boss
## 僵尸王：慢慢追 → 螺旋弹幕 → 追 → 召唤小僵尸 → 追 → 喷出几轮扇形的绿色毒液弹，循环。
## 阶数越高越难：
## - 1 阶起：螺旋弹幕两条旋臂（3 阶三条，外加一条反着转的），一次召唤更多小僵尸
## - 2 阶起：毒液弹带毒（打中会减速）；新招"毒液炸弹"（往玩家身边扔几团毒液，落地炸开一圈毒弹）
## - 3 阶：毒液喷得更多更宽

enum State { CHASE, SPIRAL, SUMMON, VOMIT, BOMBS }

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


func _ready() -> void:
	super()
	if tier >= 2:
		_order.append(State.BOMBS)


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
				var arms := mini(1 + tier, 3)
				for arm in arms:
					shoot_bullet(_spiral_angle + TAU * arm / arms, 85.0)
				if tier >= 3: # 反着转的一条
					shoot_bullet(-_spiral_angle * 1.3, 70.0).sprite.modulate = VOMIT_COLOR
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
				var count := 9 if tier >= 3 else 7
				var spread := 0.8 if tier >= 3 else 0.6
				for i in count:
					var bullet := shoot_bullet(base + lerpf(-spread, spread, float(i) / (count - 1)), 110.0)
					bullet.sprite.modulate = VOMIT_COLOR
					if tier >= 2:
						_make_poison(bullet)
				Sound.play(Sound.BOSS_SHOT, -4.0)
			if _shots_left <= 0 and _shot_timer <= 0.0:
				_back_to_chase()
		State.BOMBS:
			if _timer <= 0.0:
				_throw_bombs()
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
			_shots_left = 3 + (1 if tier >= 1 else 0) + (1 if tier >= 3 else 0)
			_shot_timer = 0.3
		State.BOMBS:
			_timer = 0.4


func _back_to_chase() -> void:
	_state = State.CHASE
	_timer = randf_range(1.5, 2.5) - 0.2 * tier # 阶数越高，喘气的时间越短


func _summon() -> void:
	_minions = _minions.filter(func(m: Enemy) -> bool: return is_instance_valid(m) and not m.is_queued_for_deletion())
	var count := mini(3 + tier, MAX_MINIONS - _minions.size())
	for i in count:
		var offset := Vector2.from_angle(TAU * i / maxf(count, 1) + randf()) * 26.0
		_minions.append(spawn_minion(MINION_SCENE, global_position + offset))
	Sound.play(Sound.THROW, -2.0)
	HitEffect.spawn(get_parent(), global_position, VOMIT_COLOR, 12, 1.0, true)


## 毒液炸弹：玩家脚下和身边各扔几团，落地后炸开一圈带毒的子弹
func _throw_bombs() -> void:
	var targets: Array[Vector2] = [player.global_position]
	for i in 1 + tier:
		targets.append(player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(30.0, 60.0))
	for pos in targets:
		delayed_burst(pos, 0.9, 8, 55.0, VOMIT_COLOR)
	Sound.play(Sound.THROW, -2.0)


## 被带毒的毒液弹打中会减速一会儿
func _make_poison(bullet: Bullet) -> void:
	bullet.slow_duration = 1.5
