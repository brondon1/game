extends MageSkill
## 潮汐【泡泡牢笼】：把最近的 4 个敌人关进泡泡 3 秒（不能动、不能攻击）。

func _init() -> void:
	display_name = "泡泡牢笼"
	description = "把最近的 4 个敌人关进泡泡 3 秒"
	cooldown = 10.0


func _activate() -> void:
	for enemy in nearest_enemies(player.global_position, 150.0, 4):
		enemy.take_damage(dmg(2))
		enemy.apply_stun(3.0, Color(0.7, 0.9, 1.3))
		overlay(enemy, "bubble.png", 3.0)
	Sound.play(Sound.BOUNCE, -4.0)
