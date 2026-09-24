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
@onready var flash: Sprite2D = $Flash
@onready var flash_light: PointLight2D = $FlashLight


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
	Sound.play(data.sound, -2.0)
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
		bullet.start_from(global_position)
		bullet.apply_effects(data)
	_muzzle_flash()
	# 后坐力小动画
	sprite.position.x = -3.0
	create_tween().tween_property(sprite, "position:x", 0.0, 0.08)


## 枪口火光：闪一下就消失，同时短暂照亮周围。
func _muzzle_flash() -> void:
	flash.position = muzzle.position + Vector2(3, 0)
	flash.rotation = randf_range(-0.3, 0.3)
	flash.show()
	flash_light.position = muzzle.position
	flash_light.enabled = true
	var tween := create_tween()
	tween.tween_interval(0.05)
	tween.tween_callback(func() -> void:
		flash.hide()
		flash_light.enabled = false)


## 近战挥砍：伤害扇形范围内的所有目标，并打掉范围内的敌方子弹。
func _swing(team: Bullet.Team, damage: int) -> void:
	# 先把上一刀的挥动动画复位，这样 global_rotation 就是瞄准方向
	if _swing_tween:
		_swing_tween.kill()
	rotation = 0.0
	sprite.position.x = 0.0
	var aim := global_rotation
	var center := global_position
	var half_arc := deg_to_rad(data.melee_arc_degrees) / 2.0
	var reach := data.melee_range + 6.0 # 加上目标自身的大致半径

	var targets := get_tree().get_nodes_in_group("player")
	if team == Bullet.Team.PLAYER:
		targets = get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("breakables")
	var hit_any := false
	for node in targets:
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
				Sound.play(Sound.DEFLECT, -4.0)
				hit_any = true

	if hit_any:
		Events.screen_shake.emit(1.5)
	SlashEffect.spawn(get_tree().current_scene, center, aim, data.melee_range, half_arc * 2.0, Color("f4f4f4"))

	_swing_tween = create_tween()
	if data.melee_arc_degrees <= 60.0:
		# 扇形很窄的武器（长矛）是往前刺
		sprite.position.x = -4.0
		_swing_tween.tween_property(sprite, "position:x", 10.0, 0.06)
		_swing_tween.tween_property(sprite, "position:x", 0.0, 0.14)
	else:
		# 其他近战武器左右交替挥
		_swing_side = -_swing_side
		rotation = -half_arc * _swing_side
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
	if data:
		sprite.offset = Vector2(-2, -data.texture.get_height() / 2.0) # 握把在贴图左侧中间
	muzzle.position = data.muzzle_offset if data else Vector2.ZERO
