extends MageSkill
## 剧毒【毒云】：在敌人扎堆处放一团毒雾 5 秒，里面的敌人持续中毒。

func _init() -> void:
	display_name = "毒云"
	description = "放一团毒雾 5 秒，里面的敌人持续中毒"
	cooldown = 9.0


func _activate() -> void:
	zone(target_spot(), 44.0, 5.0, SkillZone.Kind.POISON, dmg(2))
