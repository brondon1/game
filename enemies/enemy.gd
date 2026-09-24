class_name Enemy
extends CharacterBody2D
## 敌人基类：出生预警 → 追击玩家、碰到造成接触伤害；受击闪白和击退，死亡掉落金币和能量。
## 子类重写 _think() 实现不同的 AI（返回想要移动的方向）。

signal died(enemy: Enemy)

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

## 由房间根据楼层设置，用来让后面的楼层更难
var hp_multiplier := 1.0
var hp := 0
var player: Player

var _knockback := Vector2.ZERO
var _active := false
var _dead := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("enemies")
	max_hp = roundi(max_hp * hp_multiplier)
	hp = max_hp
	player = get_tree().get_first_node_in_group("player") as Player
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
	velocity = move_dir * speed + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()
	_try_contact_damage()


## AI：返回本帧想移动的方向（长度 0~1）。默认直接冲向玩家。
func _think(_delta: float) -> Vector2:
	return global_position.direction_to(player.global_position)


func take_damage(amount: int, direction := Vector2.ZERO) -> void:
	if not is_targetable():
		return
	hp -= amount
	_knockback = direction * knockback_strength
	_flash()
	Sound.play(Sound.HIT, -6.0)
	if hp <= 0:
		_dead = true
		_die.call_deferred()


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
	HitEffect.spawn(get_parent(), global_position, Color("f4f4f4"), 12)
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
