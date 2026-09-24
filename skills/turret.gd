class_name Turret
extends Node2D
## 工程师的炮台：自动瞄准视线内最近的敌人开火，时间到了闪烁后消失。

const BULLET_SCENE := preload("res://weapons/bullet.tscn")

@export var lifetime := 8.0
@export var fire_interval := 0.3
@export var damage := 3
@export var attack_range := 200.0

var _fire_timer := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	BlobShadow.add_to(self, 1.1)
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
	bullet.setup(Bullet.Team.PLAYER, from, angle, 320.0, maxi(1, roundi(damage * GameState.damage_mult)), attack_range + 40.0)
	Sound.play(Sound.SHOOT, -10.0)


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
