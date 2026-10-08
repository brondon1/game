extends MageSkill
## 机械师【导弹齐射】：往天上发射 6 枚导弹，依次砸向附近的敌人（落点先出现预警圈）。

const ROCKET := preload("res://assets/sprites/rocket.png")


func _init() -> void:
	display_name = "导弹齐射"
	description = "发射 6 枚导弹砸向附近敌人，每枚 8 点范围伤害"
	cooldown = 9.0


func _activate() -> void:
	var targets := nearest_enemies(player.global_position, 200.0, 6)
	var tween := create_tween()
	for i in 6:
		var spot: Vector2
		if targets.is_empty():
			spot = player.global_position + player.aim_direction * 60.0 + Vector2.from_angle(randf() * TAU) * randf_range(0, 30)
		else:
			spot = targets[i % targets.size()].global_position + Vector2.from_angle(randf() * TAU) * randf_range(0, 8)
		tween.tween_callback(_launch.bind(spot))
		tween.tween_interval(0.12)


func _launch(spot: Vector2) -> void:
	if not is_instance_valid(player):
		return
	Sound.play(Sound.THROW, -8.0)
	var ring := sprite_fx("../bomb_ring.png", world(), spot)
	ring.scale = Vector2.ONE * 0.7
	var missile := Sprite2D.new()
	missile.texture = ROCKET
	missile.rotation = PI / 2.0 # 头朝下
	missile.z_index = 10
	missile.position = spot + Vector2(0, -140)
	world().add_child(missile)
	var tween := missile.create_tween()
	tween.tween_property(missile, "position", spot, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func() -> void:
		Explosion.spawn(missile.get_parent(), spot, 26.0, dmg(8), Bullet.Team.PLAYER)
		ring.queue_free()
		missile.queue_free())
