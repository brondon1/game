extends MageSkill
## 女巫【诅咒】：诅咒周围所有敌人 6 秒：受到的伤害 +50%，死的时候炸出一圈打敌人的子弹。

const TIME := 6.0


func _init() -> void:
	display_name = "诅咒"
	description = "诅咒周围敌人 6 秒：受到伤害 +50%，死时炸出一圈子弹"
	cooldown = 12.0


func _activate() -> void:
	for enemy in enemies_near(player.global_position, 120.0):
		enemy.apply_curse(TIME)
		overlay(enemy, "curse.png", TIME * (2.0 if enemy is Boss else 1.0), Vector2(0, -26))
	SlashEffect.spawn(world(), center(), 0.0, 60.0, TAU, Color("8b88e0"))
	HitEffect.spawn(world(), center(), Color("5956bd"), 16, 1.4)
	Sound.play(Sound.BUFF, -2.0)
