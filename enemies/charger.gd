extends Enemy
## 冲锋野猪：看到玩家后原地蓄力（抖动、闪红光），然后朝玩家当时的方向直线冲锋。
## 撞到墙会晕一会儿（这是反击的好机会），撞到木箱会把木箱撞碎。

enum State { APPROACH, WINDUP, CHARGE, STUNNED }

@export var charge_speed := 260.0
@export var windup_time := 0.7
@export var charge_time := 0.9
@export var stun_time := 1.0
## 离玩家多近才开始蓄力
@export var trigger_distance := 160.0

var _state := State.APPROACH
var _timer := 0.0
var _charge_dir := Vector2.ZERO
var _walk_speed := 0.0


func _ready() -> void:
	super()
	_walk_speed = speed
	_timer = randf_range(0.5, 1.5)


func is_charging() -> bool:
	return _state == State.CHARGE


func is_stunned() -> bool:
	return _state == State.STUNNED


func _think(delta: float) -> Vector2:
	_timer -= delta
	match _state:
		State.APPROACH:
			if _timer <= 0.0 and has_line_of_sight_to_player() \
					and global_position.distance_to(player.global_position) < trigger_distance:
				_state = State.WINDUP
				_timer = windup_time
				Sound.play(Sound.CHARGE)
			return chase_direction()
		State.WINDUP:
			sprite.offset.x = randf_range(-1.0, 1.0)
			sprite.self_modulate = Color(1.7, 0.6, 0.6) if int(_timer * 12.0) % 2 == 0 else Color.WHITE
			if _timer <= 0.0:
				_state = State.CHARGE
				_timer = charge_time
				_charge_dir = global_position.direction_to(player.global_position)
				sprite.offset.x = 0.0
				sprite.self_modulate = Color.WHITE
				speed = charge_speed
				contact_damage = 2
			return Vector2.ZERO
		State.CHARGE:
			sprite.flip_h = _charge_dir.x < 0.0
			var hit := _wall_hit()
			if hit:
				_end_charge(true)
				if hit.has_method("take_damage"):
					hit.take_damage(6, _charge_dir) # 撞碎木箱
				return Vector2.ZERO
			if _timer <= 0.0:
				_end_charge(false)
			return _charge_dir
		State.STUNNED:
			sprite.rotation = sin(_timer * 30.0) * 0.1
			if _timer <= 0.0:
				sprite.rotation = 0.0
				_state = State.APPROACH
				_timer = randf_range(1.0, 2.0)
			return Vector2.ZERO
	return Vector2.ZERO


## 冲锋时撞到的墙 / 木箱（撞到其他敌人不算）。
func _wall_hit() -> Object:
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if not collider is Enemy:
			return collider
	return null


func _end_charge(hit_wall: bool) -> void:
	speed = _walk_speed
	contact_damage = 1
	if hit_wall:
		_state = State.STUNNED
		_timer = stun_time
		Events.screen_shake.emit(3.0)
		HitEffect.spawn(get_parent(), global_position + Vector2(0, -12), Color("fee761"), 8, 0.6)
	else:
		_state = State.APPROACH
		_timer = randf_range(1.0, 2.0)
