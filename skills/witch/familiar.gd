class_name Familiar
extends Node2D
## 女巫的黑猫使魔：绕着女巫飞，自动朝附近的敌人吐魔法弹，撞上它的敌方子弹会被挡掉。

const BULLET_SCENE := preload("res://weapons/bullet.tscn")

var owner_player: Player
var lifetime := 10.0
var damage := 3
var _angle := 0.0
var _fire_timer := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/sprites/skills/familiar.png")
	_sprite.hframes = 2
	add_child(_sprite)
	z_index = 2
	HitEffect.spawn(get_parent(), global_position, Color("8b88e0"), 10, 1.0)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0 or not is_instance_valid(owner_player):
		HitEffect.spawn(get_parent(), global_position, Color("8b88e0"), 8, 0.8)
		queue_free()
		return
	if lifetime < 1.5:
		visible = int(lifetime * 10.0) % 2 == 0
	_angle += delta * 2.5
	global_position = owner_player.global_position + Vector2.from_angle(_angle) * Vector2(22, 14) + Vector2(0, -14)
	_sprite.frame = int(lifetime * 8.0) % 2
	for node in get_tree().get_nodes_in_group("enemy_bullets"): # 挡子弹
		var bullet := node as Bullet
		if bullet and not bullet.is_queued_for_deletion() and bullet.global_position.distance_to(global_position) < 8.0:
			bullet.destroy()
	_fire_timer -= delta
	if _fire_timer > 0.0:
		return
	var target: Enemy = null
	var best := 160.0
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.is_targetable() and enemy.global_position.distance_to(global_position) < best:
			best = enemy.global_position.distance_to(global_position)
			target = enemy
	if target == null:
		return
	_fire_timer = 0.5
	_sprite.flip_h = target.global_position.x < global_position.x
	var bullet: Bullet = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.setup(Bullet.Team.PLAYER, global_position, global_position.angle_to_point(target.global_position + Vector2(0, -4)),
		230.0, maxi(1, roundi(damage * GameState.damage_mult)), 200.0)
	bullet.modulate = Color(0.8, 0.5, 1.6)
	Sound.play(Sound.SHOOT, -14.0)
