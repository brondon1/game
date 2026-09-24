extends Enemy
## 刺球怪：慢慢挪动，定时停下来鼓起身子，然后向四周放一圈子弹（每次错开半格角度）。

@export var fire_interval := 2.4
@export var bullet_count := 8
@export var bullet_speed := 95.0
## 放子弹前鼓起身子的预警时间
@export var charge_time := 0.5

var _timer := 0.0
var _angle_offset := 0.0


func _ready() -> void:
	super()
	_timer = randf_range(1.0, fire_interval)


func _think(delta: float) -> Vector2:
	_timer -= delta
	if _timer <= 0.0:
		_timer = fire_interval
		_burst()
	if _timer <= charge_time:
		return Vector2.ZERO # 鼓气时不动
	return chase_direction()


func _animate(delta: float, move_dir: Vector2) -> void:
	if _timer <= charge_time:
		var k := 1.0 - _timer / charge_time
		sprite.scale = _sprite_base_scale * (1.0 + k * 0.3)
		sprite.self_modulate = Color(1.0 + k * 0.6, 1.0, 1.0)
	else:
		sprite.self_modulate = Color.WHITE
		super(delta, move_dir)


func _burst() -> void:
	for i in bullet_count:
		shoot_bullet(TAU * i / bullet_count + _angle_offset, bullet_speed)
	_angle_offset = PI / bullet_count - _angle_offset # 下一圈错开，让缝隙换位置
	Sound.play(Sound.BOSS_SHOT, -6.0)
