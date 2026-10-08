extends MageSkill
## 机械师【超载】：机甲过载 5 秒：射速 +60%，开枪不耗能量。

func _init() -> void:
	display_name = "超载"
	description = "机甲过载 5 秒：射速 +60%，开枪不耗能量"
	cooldown = 14.0
	duration = 5.0


func _activate() -> void:
	GameState.fire_rate_mult += 0.6
	GameState.free_energy = true
	GameState.stats_changed.emit()
	player.sprite.self_modulate = Color(1.5, 1.0, 0.6)
	HitEffect.spawn(world(), center(), Color("ee8e2e"), 14, 1.2)
	Sound.play(Sound.CHARGE, -2.0)


func _end() -> void:
	GameState.fire_rate_mult -= 0.6
	GameState.free_energy = false
	GameState.stats_changed.emit()
	if is_instance_valid(player):
		player.sprite.self_modulate = Color.WHITE
