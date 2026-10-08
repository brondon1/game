extends MageSkill
## 冰霜【暴风雪】：在敌人扎堆的地方下 5 秒冰雹，持续伤害并减速。

func _init() -> void:
	display_name = "暴风雪"
	description = "敌人扎堆处下 5 秒冰雹：每 0.5 秒 2 点伤害并减速"
	cooldown = 10.0


func _activate() -> void:
	zone(target_spot(), 50.0, 5.0, SkillZone.Kind.FROST, dmg(2))
