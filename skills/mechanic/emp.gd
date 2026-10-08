extends MageSkill
## 机械师【电磁脉冲】：放出一圈电磁波，附近敌人瘫痪 2 秒（不能动、不能开火），清掉身边的子弹。

func _init() -> void:
	display_name = "电磁脉冲"
	description = "电磁波让附近敌人瘫痪 2 秒，并清掉身边的子弹"
	cooldown = 11.0


func _activate() -> void:
	clear_bullets(center(), 100.0)
	for enemy in enemies_near(player.global_position, 100.0):
		enemy.apply_stun(2.0, Color(0.6, 1.3, 1.5))
		Lightning._bolt(world(), center(), enemy.global_position + Vector2(0, -4))
	SlashEffect.spawn(world(), center(), 0.0, 50.0, TAU, Color("72d6ce"))
	Events.screen_shake.emit(3.0)
	Sound.play(Sound.CHARGE, -2.0)
