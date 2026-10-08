class_name SkillMover
extends Node2D
## 会往前移动的技能体（龙卷风、潮汐浪）：沿 velocity 飞 lifetime 秒，撞墙停下。
## - 碰到的敌方子弹直接吞掉
## - 碰到的敌人：每个只受一次 hit_damage（tick > 0 时每 tick 秒再伤一次），push 把它推开，drag 把它拖着一起走

var velocity := Vector2.ZERO
var lifetime := 2.0
var radius := 16.0
var hit_damage := 3
var tick := 0.0
var push := 0.0
var drag := false
var texture: Texture2D
var hframes := 1

var _hit: Dictionary = {}
var _anim := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.hframes = hframes
	_sprite.offset = Vector2(0, -texture.get_height() / 2.0 + 4.0)
	_sprite.flip_h = velocity.x < 0.0
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		_finish()
		return
	_anim += delta
	_sprite.frame = int(_anim * 10.0) % hframes
	var step := velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step * 3.0, Bullet.LAYER_WORLD)
	if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		position += step
	else:
		velocity = Vector2.ZERO # 撞墙停在原地，转完剩下的时间
	for node in get_tree().get_nodes_in_group("enemy_bullets"):
		var bullet := node as Bullet
		if bullet and not bullet.is_queued_for_deletion() and bullet.global_position.distance_to(global_position) <= radius:
			bullet.destroy()
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not enemy.is_targetable() or enemy.global_position.distance_to(global_position) > radius:
			continue
		var id := enemy.get_instance_id()
		var now := Time.get_ticks_msec() / 1000.0
		if not _hit.has(id) or (tick > 0.0 and now - float(_hit[id]) >= tick):
			_hit[id] = now
			var dir := velocity.normalized() if velocity != Vector2.ZERO else global_position.direction_to(enemy.global_position)
			enemy.take_damage(hit_damage, dir * push)
		if drag:
			enemy.pull((global_position - enemy.global_position) * 6.0 + velocity)


func _finish() -> void:
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
