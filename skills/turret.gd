class_name Turret
extends Node2D
## 女巫召唤的奥术炮塔：瞄准视线内最近的敌人发射跟踪火箭（和火箭筒一样落地爆炸，飞行中会拐弯追敌人），
## 时间到了闪烁后消失。可以同时存在好几座（上限见 DeployTurret.MAX_TURRETS）。

const BULLET_SCENE := preload("res://weapons/bullet.tscn")
const ROCKET_TEXTURE := preload("res://assets/sprites/rocket.png")
const GROUP := &"turrets"

@export var lifetime := 12.0
@export var fire_interval := 0.8
@export var damage := 5
@export var attack_range := 220.0
@export var rocket_speed := 170.0
@export var explosion_radius := 30.0
## 跟踪的转向速度（和追踪弩同一套机制）
@export var homing := 4.0

var _fire_timer := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group(GROUP)
	BlobShadow.add_to(self, 1.1)
	sprite.self_modulate = Color(1.0, 0.75, 1.35) # 染成紫色，配合女巫的奥术主题
	sprite.scale = Vector2(0.2, 0.2)
	create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if lifetime < 1.5:
		sprite.visible = int(lifetime * 10.0) % 2 == 0 # 快消失时闪烁
	_fire_timer -= delta
	if _fire_timer > 0.0:
		return
	var target := _find_target()
	if target == null:
		return
	_fire_timer = fire_interval
	var from := global_position + Vector2(0, -8)
	var angle := from.angle_to_point(target.global_position + Vector2(0, -4))
	sprite.flip_h = target.global_position.x < global_position.x
	var bullet: Bullet = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.setup(Bullet.Team.PLAYER, from, angle, rocket_speed, maxi(1, roundi(damage * GameState.damage_mult)), attack_range + 80.0)
	bullet.sprite.texture = ROCKET_TEXTURE
	bullet.explosion_radius = explosion_radius
	bullet.homing = homing
	Sound.play(Sound.SHOOT, -10.0)


## 新炮塔放下时，超出上限的最老那座提前收起来
func dismiss() -> void:
	remove_from_group(GROUP)
	lifetime = minf(lifetime, 0.4)


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_dist := attack_range
	var space := get_world_2d().direct_space_state
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not enemy.is_targetable():
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist >= best_dist:
			continue
		var query := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -8), enemy.global_position, Bullet.LAYER_WORLD)
		if space.intersect_ray(query).is_empty():
			best = enemy
			best_dist = dist
	return best
