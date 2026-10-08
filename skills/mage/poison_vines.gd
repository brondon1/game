extends MageSkill
## 剧毒【藤蔓缠绕】：附近的敌人被藤蔓缠住 2 秒，动不了，并中毒。

func _init() -> void:
	display_name = "藤蔓缠绕"
	description = "缠住附近敌人 2 秒（不能动、不能攻击），并让它们中毒"
	cooldown = 9.0


func _activate() -> void:
	for enemy in enemies_near(player.global_position, 100.0):
		enemy.apply_stun(2.0, Color(0.8, 1.2, 0.7))
		enemy.apply_poison(2.0, dmg(1))
		overlay(enemy, "vines.png", 2.0, Vector2(0, -4))
	HitEffect.spawn(world(), player.global_position, Color("4ba747"), 12, 1.2, true)
