extends MageSkill
## 大地【地刺】：朝瞄准方向一路冒出 6 根地刺，每根都有伤害（碰到墙就停）。

func _init() -> void:
	display_name = "地刺"
	description = "朝前方冒出一排地刺，每根 8 点伤害"
	cooldown = 5.0


func _activate() -> void:
	var dir := player.aim_direction
	var tween := create_tween()
	for i in 6:
		var pos := player.global_position + dir * (20.0 + i * 18.0)
		if reach_point(player.global_position, dir, 20.0 + i * 18.0, 0.0) != pos:
			break # 被墙挡住了
		tween.tween_callback(_spike.bind(pos))
		tween.tween_interval(0.05)


func _spike(pos: Vector2) -> void:
	if not is_instance_valid(player):
		return
	var spike := sprite_fx("spike.png", world(), pos)
	spike.offset = Vector2(0, -8)
	spike.scale = Vector2(1, 0.1)
	var tween := spike.create_tween()
	tween.tween_property(spike, "scale", Vector2.ONE, 0.08)
	tween.tween_interval(0.35)
	tween.tween_property(spike, "modulate:a", 0.0, 0.2)
	tween.tween_callback(spike.queue_free)
	hurt_area(pos, 14.0, dmg(8), 0.4)
	HitEffect.spawn(world(), pos, Color("775c55"), 4, 0.6, true)
