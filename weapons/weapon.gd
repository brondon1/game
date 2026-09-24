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


func _refresh() -> void:
	sprite.texture = data.texture if data else null
	muzzle.position = data.muzzle_offset if data else Vector2.ZERO
