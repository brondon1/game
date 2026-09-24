class_name Enemy
extends CharacterBody2D
## 敌人基类：出生预警 → 追击玩家、碰到造成接触伤害；受击闪白和击退，死亡掉落金币和能量。
## 子类重写 _think() 实现不同的 AI（返回想要移动的方向）。
## 追击用 chase_direction()：能直接看到玩家就直线走，被石柱挡住时沿导航网格绕路。

signal died(enemy: Enemy)
## 召唤 / 分裂出新的敌人时发出，房间靠它把新敌人也算进这一波
signal spawned_minion(minion: Enemy)

const PICKUP_SCENE := preload("res://pickups/pickup.tscn")
const BULLET_SCENE := preload("res://weapons/bullet.tscn")

@export var max_hp := 10
@export var speed := 40.0
@export var contact_damage := 1
@export var contact_range := 12.0
@export var knockback_strength := 140.0
@export var coin_drop := 1
@export var energy_drop := 4
## 出生前的预警时间（这段时间里半透明、不会动也不会受伤）
@export var spawn_delay := 0.6
## 死亡时碎片的颜色
@export var death_color := Color("f4f4f4")
## 脚下阴影的大小
@export var shadow_scale := 1.0

## 多久重新计算一次绕路路线（秒）
const REPATH_INTERVAL := 0.25

## 由房间根据楼层设置，用来让后面的楼层更难
var hp_multiplier := 1.0
var hp := 0
var player: Player

var _knockback := Vector2.ZERO
var _active := false
var _dead := false
var _nav: NavigationAgent2D
var _repath_timer := 0.0
var _walk_time := 0.0
var _slow_time := 0.0
var _sprite_base_y := 0.0
var _sprite_base_scale := Vector2.ONE

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("enemies")
	max_hp = roundi(max_hp * hp_multiplier)
	hp = max_hp
	player = get_tree().get_first_node_in_group("player") as Player
	_sprite_base_y = sprite.position.y
	_sprite_base_scale = sprite.scale
	BlobShadow.add_to(self, shadow_scale)
	_nav = NavigationAgent2D.new()
	_nav.path_desired_distance = 6.0
	_nav.target_desired_distance = 6.0
	add_child(_nav)
	# 出生预警：从半透明淡入，结束后才开始行动
	collision_layer = 0
	sprite.modulate.a = 0.25
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, spawn_delay)
	tween.tween_callback(_activate)


func _activate() -> void:
	_active = true
	collision_layer = Bullet.LAYER_ENEMY


func is_targetable() -> bool:
	return _active and not _dead


func _physics_process(delta: float) -> void:
	if not _active or _dead:
		return
	var move_dir := Vector2.ZERO
	if player and not player.is_dead():
		move_dir = _think(delta)
		sprite.flip_h = player.global_position.x < global_position.x
	var current_speed := speed
	if _slow_time > 0.0:
		_slow_time -= delta
		current_speed *= 0.45
		if _slow_time <= 0.0:
			sprite.self_modulate = Color.WHITE
	velocity = move_dir * current_speed + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()
	_animate(delta, move_dir)
	_try_contact_damage()


## 移动时一颠一颠、挤压拉伸，看起来更有弹性。
func _animate(delta: float, move_dir: Vector2) -> void:
	if move_dir.length() > 0.1:
		_walk_time += delta * 12.0
		var s := sin(_walk_time)
		sprite.position.y = _sprite_base_y - absf(s) * 1.5
		sprite.scale = _sprite_base_scale * Vector2(1.0 + s * 0.06, 1.0 - s * 0.06)
	else:
		sprite.position.y = lerpf(sprite.position.y, _sprite_base_y, 0.3)
		sprite.scale = sprite.scale.lerp(_sprite_base_scale, 0.3)


## AI：返回本帧想移动的方向（长度 0~1）。默认追向玩家。
func _think(_delta: float) -> Vector2:
	return chase_direction()


## 朝玩家移动的方向：能直接看到玩家就直线走，被障碍物挡住时沿导航网格绕路。
func chase_direction() -> Vector2:
	var direct := global_position.direction_to(player.global_position)
	if has_line_of_sight_to_player():
		return direct
	_repath_timer -= get_physics_process_delta_time()
	if _repath_timer <= 0.0:
		_repath_timer = REPATH_INTERVAL
		_nav.target_position = player.global_position
	if _nav.is_navigation_finished():
		return direct
	var next := _nav.get_next_path_position()
	return direct if next.distance_to(global_position) < 1.0 else global_position.direction_to(next)


func take_damage(amount: int, direction := Vector2.ZERO) -> void:
	if not is_targetable():
		return
	hp -= amount
	_knockback = direction * knockback_strength
	_flash()
	DamageNumber.spawn(get_parent(), global_position, amount)
	Sound.play(Sound.HIT, -6.0)
	if hp <= 0:
		_dead = true
		_die.call_deferred()


## 被冰冻类武器命中：一段时间内移动变慢，身体变成淡蓝色。
func apply_slow(duration: float) -> void:
	_slow_time = maxf(_slow_time, duration)
	sprite.self_modulate = Color(0.6, 0.85, 1.4)


## 召唤或分裂出一个新敌人（和自己同样的血量倍率），并通知房间。
func spawn_minion(scene: PackedScene, pos: Vector2) -> Enemy:
	var minion: Enemy = scene.instantiate()
	minion.position = pos
	minion.hp_multiplier = hp_multiplier
	get_parent().add_child(minion)
	spawned_minion.emit(minion)
	return minion


## 朝某个角度发射一颗敌方子弹，子类可复用。
func shoot_bullet(angle: float, bullet_speed: float, damage := 1) -> void:
	var bullet: Bullet = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.setup(Bullet.Team.ENEMY, global_position + Vector2(0, -4), angle, bullet_speed, damage, 400.0)
	Sound.play(Sound.ENEMY_SHOT, -10.0)


func has_line_of_sight_to_player() -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position, Bullet.LAYER_WORLD)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _try_contact_damage() -> void:
	if contact_damage > 0 and player and global_position.distance_to(player.global_position) <= contact_range:
		player.take_damage(contact_damage)


func _flash() -> void:
	var mat := sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash", 1.0)
		create_tween().tween_property(mat, "shader_parameter/flash", 0.0, 0.12)


func _die() -> void:
	for i in coin_drop:
		_drop(Pickup.Kind.COIN, 1)
	if energy_drop > 0:
		_drop(Pickup.Kind.ENERGY, energy_drop)
	HitEffect.spawn(get_parent(), global_position + Vector2(0, -4), death_color, 16, 1.3)
	Events.screen_shake.emit(1.5)
	Sound.play(Sound.ENEMY_DIE, -3.0)
	GameState.kills += 1
	died.emit(self)
	queue_free()


func _drop(kind: Pickup.Kind, amount: int) -> void:
	var pickup: Pickup = PICKUP_SCENE.instantiate()
	pickup.kind = kind
	pickup.amount = amount
	pickup.position = position
	get_parent().add_child(pickup)
