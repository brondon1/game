extends MageSkill
## 火焰【烈焰新星】：身边炸开一圈火环，清掉身边子弹，脚下烧 3 秒。

func _init() -> void:
	display_name = "烈焰新星"
	description = "身边炸开火环：8 点伤害并击退，清掉身边子弹，脚下燃烧 3 秒"
	cooldown = 8.0


func _activate() -> void:
	clear_bullets(center(), 60.0)
	hurt_area(player.global_position, 56.0, dmg(8), 1.6)
	SlashEffect.spawn(world(), center(), 0.0, 28.0, TAU, Color("ee8e2e"))
	HitEffect.spawn(world(), center(), Color("ee8e2e"), 20, 1.6)
	zone(player.global_position, 50.0, 3.0, SkillZone.Kind.BURN, dmg(2))
	Events.screen_shake.emit(4.0)
