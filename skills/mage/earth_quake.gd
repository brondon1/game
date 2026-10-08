extends MageSkill
## 大地【地震】：周围所有敌人眩晕 1.5 秒并受到伤害。

func _init() -> void:
	display_name = "地震"
	description = "周围所有敌人眩晕 1.5 秒，受到 6 点伤害"
	cooldown = 12.0


func _activate() -> void:
	for enemy in enemies_near(player.global_position, 240.0):
		enemy.take_damage(dmg(6))
		enemy.apply_stun(1.5, Color(1.2, 1.0, 0.7))
		HitEffect.spawn(world(), enemy.global_position, Color("aa8d7a"), 6, 0.8, true)
	Events.screen_shake.emit(10.0)
	Sound.play(Sound.EXPLOSION, -2.0)
