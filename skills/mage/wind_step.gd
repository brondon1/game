extends MageSkill
## 疾风【疾风步】：3 秒内移速 +50%，有一半概率闪开伤害。

func _init() -> void:
	display_name = "疾风步"
	description = "3 秒内移速 +50%，50% 概率闪避伤害"
	cooldown = 9.0
	duration = 3.0


func _activate() -> void:
	GameState.speed_mult += 0.5
	player.dodge_chance = 0.5
	player.sprite.self_modulate = Color(0.8, 1.3, 1.3)
	HitEffect.spawn(world(), player.global_position, Color("cae6f5"), 10, 1.0, true)


func _end() -> void:
	GameState.speed_mult -= 0.5
	if is_instance_valid(player):
		player.dodge_chance = 0.0
		player.sprite.self_modulate = Color.WHITE
