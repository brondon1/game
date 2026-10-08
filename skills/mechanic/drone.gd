class_name Drone
extends Node2D
## 机械师的无人机：绕着玩家飞。
## - REPAIR 维修无人机：每 2 秒给玩家回 1 点血（最多 3 点），并用电弧打掉飞到玩家身边的敌方子弹
## - ATTACK 攻击无人机：自动用机枪扫射附近的敌人

enum Mode { REPAIR, ATTACK }

const BULLET_SCENE := preload("res://weapons/bullet.tscn")

var mode := Mode.ATTACK
var owner_player: Player
var lifetime := 8.0
## 绕圈的起始角度（两架攻击无人机错开半圈）
var angle := 0.0
var damage := 2
var _timer := 0.0
var _heal_timer := 2.0
var _healed := 0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/sprites/skills/%s.png" % ("drone_repair" if mode == Mode.REPAIR else "drone_attack"))
	_sprite.hframes = 2
	add_child(_sprite)
	z_index = 3
	HitEffect.spawn(get_parent(), global_position, Color("b6cbcf"), 8, 0.8)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0 or not is_instance_valid(owner_player):
		HitEffect.spawn(get_parent(), global_position, Color("b6cbcf"), 8, 0.8)
		queue_free()
		return
	if lifetime < 1.5:
		visible = int(lifetime * 10.0) % 2 == 0
	angle += delta * 2.2
	global_position = owner_player.global_position + Vector2.from_angle(angle) * Vector2(20, 12) + Vector2(0, -20)
	_sprite.frame = int(lifetime * 12.0) % 2 # 螺旋桨
	_timer -= delta
	if mode == Mode.REPAIR:
		_repair(delta)
	elif _timer <= 0.0:
		_shoot()


func _repair(delta: float) -> void:
	_heal_timer -= delta
	if _heal_timer <= 0.0 and _healed < 3 and GameState.hp < GameState.max_hp:
		_heal_timer = 2.0
		_healed += 1
		GameState.heal(1)
		HitEffect.spawn(get_parent(), owner_player.global_position + Vector2(0, -8), Color("4ba747"), 6, 0.6)
	if _timer > 0.0:
		return
	for node in get_tree().get_nodes_in_group("enemy_bullets"): # 电弧打掉一颗靠近的子弹
		var bullet := node as Bullet
		if bullet and not bullet.is_queued_for_deletion() and bullet.global_position.distance_to(owner_player.global_position) < 34.0:
			_timer = 0.25
			Lightning._bolt(get_parent(), global_position, bullet.global_position)
			bullet.destroy()
			return


func _shoot() -> void:
	var target: Enemy = null
	var best := 150.0
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.is_targetable() and enemy.global_position.distance_to(global_position) < best:
			best = enemy.global_position.distance_to(global_position)
			target = enemy
	if target == null:
		return
	_timer = 0.25
	var bullet: Bullet = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.setup(Bullet.Team.PLAYER, global_position, global_position.angle_to_point(target.global_position + Vector2(0, -4)) + randf_range(-0.08, 0.08),
		300.0, maxi(1, roundi(damage * GameState.damage_mult)), 180.0)
	Sound.play(Sound.SHOOT, -16.0)
