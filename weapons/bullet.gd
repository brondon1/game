class_name Bullet
extends Area2D
## 子弹：直线飞行，撞墙或命中目标后消失。阵营决定它和谁发生碰撞。
## 由武器通过 apply_effects() 开启特殊效果：爆炸、反弹、减速、追踪。

enum Team { PLAYER, ENEMY }

const PLAYER_TEXTURE := preload("res://assets/sprites/bullet_player.png")
const ENEMY_TEXTURE := preload("res://assets/sprites/bullet_enemy.png")
const HOMING_RANGE := 160.0

# 碰撞层（与 项目设置 → Layer Names → 2D Physics 对应）
const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 4
const LAYER_PLAYER_BULLET := 8
const LAYER_ENEMY_BULLET := 16

var team := Team.PLAYER
var damage := 1
var piercing := false

# 特殊效果（见 WeaponData 的“子弹特效”分组）
var explosion_radius := 0.0
var bounces_left := 0
var slow_duration := 0.0
var homing := 0.0

var _velocity := Vector2.ZERO
var _range_left := 300.0
var _already_hit: Array[Node2D] = []
var _done := false
var _homing_target: Node2D
var _retarget_timer := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(p_team: Team, pos: Vector2, angle: float, speed: float, p_damage: int,
		max_range: float, p_piercing := false) -> void:
	team = p_team
	global_position = pos
	rotation = angle
	damage = p_damage
	piercing = p_piercing
	_velocity = Vector2.from_angle(angle) * speed
	_range_left = max_range
	var is_player := team == Team.PLAYER
	collision_layer = LAYER_PLAYER_BULLET if is_player else LAYER_ENEMY_BULLET
	collision_mask = LAYER_WORLD | (LAYER_ENEMY if is_player else LAYER_PLAYER)
	sprite.texture = PLAYER_TEXTURE if is_player else ENEMY_TEXTURE
	add_to_group("player_bullets" if is_player else "enemy_bullets") # 近战武器靠这个分组找到要打掉的子弹


## 按武器数据开启子弹特效和贴图。
func apply_effects(data: WeaponData) -> void:
	if data.bullet_texture:
		sprite.texture = data.bullet_texture
	explosion_radius = data.explosion_radius
	bounces_left = data.bounces
	slow_duration = data.slow_duration
	homing = data.homing


func _physics_process(delta: float) -> void:
	if homing > 0.0:
		_steer(delta)
	var step := _velocity * delta
	if bounces_left > 0 and _try_bounce(step):
		return
	position += step
	_range_left -= step.length()
	if _range_left <= 0.0:
		if explosion_radius > 0.0:
			destroy() # 火箭飞到尽头也会爆
		else:
			queue_free()


## 反弹：先用射线看这一步会不会撞墙，会的话按墙的法线反射。
func _try_bounce(step: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step, LAYER_WORLD)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.collider.has_method("take_damage"):
		return false # 木箱之类能打坏的东西照常命中
	bounces_left -= 1
	_velocity = _velocity.bounce(hit.normal)
	global_position = hit.position + hit.normal * 2.0
	rotation = _velocity.angle()
	_already_hit.clear() # 反弹后可以再次命中同一个敌人
	Sound.play(Sound.BOUNCE, -8.0)
	return true


## 追踪：慢慢把飞行方向转向最近的目标。
func _steer(delta: float) -> void:
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or not is_instance_valid(_homing_target):
		_retarget_timer = 0.15
		_homing_target = _find_homing_target()
	if _homing_target == null:
		return
	var desired := global_position.direction_to(_homing_target.global_position + Vector2(0, -4)).angle()
	var current := _velocity.angle()
	var turn := clampf(angle_difference(current, desired), -homing * delta, homing * delta)
	_velocity = _velocity.rotated(turn)
	rotation = _velocity.angle()


func _find_homing_target() -> Node2D:
	var group := "enemies" if team == Team.PLAYER else "player"
	var best: Node2D = null
	var best_dist := HOMING_RANGE
	for node in get_tree().get_nodes_in_group(group):
		var target := node as Node2D
		if target is Enemy and not target.is_targetable():
			continue
		var dist := global_position.distance_to(target.global_position)
		if dist < best_dist:
			best = target
			best_dist = dist
	return best


func _on_body_entered(body: Node2D) -> void:
	if _done:
		return
	if body.has_method("take_damage"):
		if body in _already_hit:
			return
		_already_hit.append(body)
		body.take_damage(damage, _velocity.normalized())
		if slow_duration > 0.0 and body.has_method("apply_slow"):
			body.apply_slow(slow_duration)
		if piercing:
			return
	elif bounces_left > 0:
		return # 墙交给 _try_bounce 处理
	destroy()


## 子弹消失（撞墙、命中或被近战打掉），带一个小火花；爆炸弹会炸开。
func destroy() -> void:
	if _done:
		return
	_done = true
	if explosion_radius > 0.0:
		Explosion.spawn(get_parent(), global_position, explosion_radius, damage, team)
	else:
		var color := Color("ffcd75") if team == Team.PLAYER else Color("ef7d57")
		if slow_duration > 0.0:
			color = Color("73eff7")
		HitEffect.spawn(get_parent(), global_position, color)
	queue_free()
