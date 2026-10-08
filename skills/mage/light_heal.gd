extends MageSkill
## 圣光【治愈之光】：回 2 点血，同时清掉全屏的敌方子弹。

func _init() -> void:
	display_name = "治愈之光"
	description = "回复 2 点生命，清掉全屏的敌方子弹"
	cooldown = 16.0


func _activate() -> void:
	GameState.heal(2)
	Sound.play(Sound.HEAL)
	clear_bullets(center(), 500.0)
	HitEffect.spawn(world(), center(), Color("facb3e"), 20, 1.4)
	SlashEffect.spawn(world(), center(), 0.0, 60.0, TAU, Color("fdf7ed"))
