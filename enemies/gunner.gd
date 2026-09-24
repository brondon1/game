extends Enemy
## 远程敌人：和玩家保持距离、左右绕圈走位，定时朝玩家打出扇形子弹。被障碍物挡住时会绕过去找射击角度。

@export var preferred_distance := 110.0
@export var fire_interval := 2.0
@export var bullet_count := 3
@export var spread_degrees := 30.0
@export var bullet_speed := 110.0

var _fire_timer := 0.0
var _strafe_timer := 0.0
var _strafe_dir := 1.0
var _aim_pause := 0.0


func _ready() -> void:
	super()
	_fire_timer = randf_range(1.0, fire_interval)


func _think(delta: float) -> Vector2:
	_fire_timer -= delta
	if _aim_pause > 0.0:
		_aim_pause -= delta
		return Vector2.ZERO
	if _fire_timer <= 0.0 and has_line_of_sight_to_player():
		_fire_timer = fire_interval
		_aim_pause = 0.35 # 开枪时停顿一下，给玩家反应时间
		_fire_fan()
		return Vector2.ZERO

	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		_strafe_timer = randf_range(1.0, 2.5)
		_strafe_dir = [-1.0, 1.0].pick_random()

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player / maxf(dist, 0.001)
	if dist > preferred_distance + 20.0 or not has_line_of_sight_to_player():
		return chase_direction() # 太远或被挡住：靠近 / 绕过去
	if dist < preferred_distance - 20.0:
		return -dir
	return dir.orthogonal() * _strafe_dir * 0.6


func _fire_fan() -> void:
	var base := global_position.angle_to_point(player.global_position)
	var spread := deg_to_rad(spread_degrees)
	for i in bullet_count:
		var t := 0.5 if bullet_count == 1 else float(i) / (bullet_count - 1)
		shoot_bullet(base + lerpf(-spread, spread, t) * 0.5, bullet_speed)
