extends MageSkill
## 冰霜【冰霜新星】：冻住身边所有敌人 2.5 秒（冻住时受到的伤害 +50%），清掉身边子弹。

func _init() -> void:
	display_name = "冰霜新星"
	description = "冻住身边敌人 2.5 秒（冰冻时受到的伤害 +50%），清掉身边子弹"
	cooldown = 9.0


func _activate() -> void:
	clear_bullets(center(), 80.0)
	for enemy in enemies_near(player.global_position, 80.0):
		enemy.take_damage(dmg(4))
		enemy.apply_stun(2.5, Color(0.55, 0.85, 1.6), true)
	SlashEffect.spawn(world(), center(), 0.0, 40.0, TAU, Color("cae6f5"))
	HitEffect.spawn(world(), center(), Color("cae6f5"), 20, 1.5)
	Events.screen_shake.emit(3.0)
