class_name Weapon
extends Node2D
## 手持的枪：按 WeaponData 发射子弹。放在一个会旋转朝向目标的节点下面。

const BULLET_SCENE := preload("res://weapons/bullet.tscn")

@export var data: WeaponData:
	set(value):
		data = value
		if is_node_ready():
			_refresh()

var _cooldown := 0.0
var _swing_tween: Tween
var _swing_side := 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	_refresh()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)


func is_ready_to_fire() -> bool:
	return data != null and _cooldown <= 0.0


func fire(team: Bullet.Team, damage_mult := 1.0, fire_rate_mult := 1.0) -> void:
	if not is_ready_to_fire():
		return
	_cooldown = data.fire_interval / fire_rate_mult
	var damage := maxi(1, roundi(data.damage * damage_mult))
	if data.is_melee:
		_swing(team, damage)
		return
	var spread := deg_to_rad(data.spread_degrees)
	for i in data.bullets_per_shot:
		var offset := randf_range(-spread, spread) * 0.5
		if data.bullets_per_shot > 1:
			# 多发子弹（霰弹）均匀铺开，再加一点随机
			offset = lerpf(-spread, spread, float(i) / (data.bullets_per_shot - 1)) * 0.5 + randf_range(-0.05, 0.05)
		var bullet: Bullet = BULLET_SCENE.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.setup(team, muzzle.global_position, global_rotation + offset,
				data.bullet_speed * randf_range(0.95, 1.05), damage, data.bullet_range, data.piercing)
	# 后坐力小动画
	sprite.position.x = -3.0
	create_tween().tween_property(sprite, "position:x", 0.0, 0.08)


## 近战挥砍：伤害扇形范围内的所有目标，并打掉范围内的敌方子弹。
func _swing(team: Bullet.Team, damage: int) -> void:
	# 先把上一刀的挥动动画复位，这样 global_rotation 就是瞄准方向
	if _swing_tween:
		_swing_tween.kill()
	rotation = 0.0
	var aim := global_rotation
	var center := global_position
	var half_arc := deg_to_rad(data.melee_arc_degrees) / 2.0
	var reach := data.melee_range + 6.0 # 加上目标自身的大致半径

	var target_group := "enemies" if team == Bullet.Team.PLAYER else "player"
	var hit_any := false
	for node in get_tree().get_nodes_in_group(target_group):
		var target := node as Node2D
		if target == null or not target.has_method("take_damage"):
			continue
		if target is Enemy and not target.is_targetable():
			continue
		if _in_arc(center, aim, half_arc, reach, target.global_position + Vector2(0, -4)):
			var dir := center.direction_to(target.global_position)
			target.take_damage(damage, dir * data.knockback)
			HitEffect.spawn(target.get_parent(), target.global_position, Color("f4f4f4"), 8)
			hit_any = true

	if data.deflects_bullets:
		var bullet_group := "enemy_bullets" if team == Bullet.Team.PLAYER else "player_bullets"
		for node in get_tree().get_nodes_in_group(bullet_group):
			var bullet := node as Bullet
			if bullet and _in_arc(center, aim, half_arc, reach, bullet.global_position):
				bullet.destroy()
				hit_any = true

	if hit_any:
		Events.screen_shake.emit(1.5)
	SlashEffect.spawn(get_tree().current_scene, center, aim, data.melee_range, half_arc * 2.0, Color("f4f4f4"))

	# 挥动动画：左右交替挥
	_swing_side = -_swing_side
	rotation = -half_arc * _swing_side
	_swing_tween = create_tween()
	_swing_tween.tween_property(self, "rotation", half_arc * _swing_side, 0.08)
	_swing_tween.tween_property(self, "rotation", 0.0, 0.12)


func _in_arc(center: Vector2, aim: float, half_arc: float, reach: float, point: Vector2) -> bool:
	var offset := point - center
	if offset.length() > reach:
		return false
	# 贴脸的目标不管角度都算命中
	return offset.length() < 10.0 or absf(angle_difference(aim, offset.angle())) <= half_arc


func _refresh() -> void:
	if _swing_tween:
		_swing_tween.kill()
	rotation = 0.0
	sprite.texture = data.texture if data else null
	muzzle.position = data.muzzle_offset if data else Vector2.ZERO
