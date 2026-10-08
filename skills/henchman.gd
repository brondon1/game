class_name Henchman
extends CharacterBody2D
## 狂战士召唤的小弟：跑去砍最近的敌人，附近没敌人就跟在狂战士身边。
## 会被敌人的子弹打（和玩家在同一个碰撞层），血打光就倒下；进下一层时消失。

const GROUP := &"henchmen"
const TEXTURE := preload("res://assets/sprites/henchman.png")

@export var max_hp := 8
@export var speed := 85.0
@export var damage := 4
@export var attack_interval := 0.6
@export var attack_range := 14.0
@export var sight_range := 170.0

var hp := 0
var owner_player: Player
var _attack_timer := 0.0
var _anim := 0.0
var _invincible := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group(GROUP)
	hp = max_hp
	collision_layer = Bullet.LAYER_PLAYER # 敌人的子弹能打到它
	collision_mask = Bullet.LAYER_WORLD
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	shape.position = Vector2(0, -3)
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.hframes = 8
	_sprite.offset = Vector2(0, -7)
	add_child(_sprite)
	BlobShadow.add_to(self, 0.8)
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	HitEffect.spawn(get_parent(), global_position, Color("aa8d7a"), 10, 1.0, true)


func _physics_process(delta: float) -> void:
	_attack_timer -= delta
	_invincible -= delta
	_anim += delta
	var target := _find_target()
	var dir := Vector2.ZERO
	if target:
		var dist := global_position.distance_to(target.global_position)
		if dist > attack_range:
			dir = global_position.direction_to(target.global_position)
		elif _attack_timer <= 0.0:
			_attack(target)
		_sprite.flip_h = target.global_position.x < global_position.x
	elif is_instance_valid(owner_player) and global_position.distance_to(owner_player.global_position) > 28.0:
		dir = global_position.direction_to(owner_player.global_position)
		_sprite.flip_h = dir.x < 0.0
	velocity = dir * speed * GameState.speed_mult
	move_and_slide()
	var moving := dir != Vector2.ZERO
	_sprite.frame = (4 if moving else 0) + int(_anim * (10.0 if moving else 6.0)) % 4


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_dist := sight_range
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.is_targetable():
			var dist := global_position.distance_to(enemy.global_position)
			if dist < best_dist:
				best = enemy
				best_dist = dist
	return best


func _attack(target: Enemy) -> void:
	_attack_timer = attack_interval
	var dir := global_position.direction_to(target.global_position)
	target.take_damage(maxi(1, roundi(damage * GameState.damage_mult)), dir * 0.6)
	SlashEffect.spawn(get_parent(), global_position + Vector2(0, -4), dir.angle(), 10.0, PI * 0.8, Color("f4f4f4"))
	Sound.play(Sound.HIT, -10.0)


func take_damage(amount: int, _direction := Vector2.ZERO) -> void:
	if _invincible > 0.0 or hp <= 0:
		return
	_invincible = 0.4
	hp -= amount
	_sprite.modulate = Color(1, 0.3, 0.3)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.2)
	if hp <= 0:
		dismiss()


## 倒下 / 被新召唤的小弟顶替：冒一团烟消失
func dismiss() -> void:
	remove_from_group(GROUP)
	set_physics_process(false)
	collision_layer = 0
	HitEffect.spawn(get_parent(), global_position, Color("775c55"), 10, 1.0, true)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
