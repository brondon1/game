extends MageSkill
## 潮汐【治愈之泉】：脚下一汪泉水，站在里面每 1.5 秒回 1 点血，持续 6 秒。

func _init() -> void:
	display_name = "治愈之泉"
	description = "脚下出现泉水 6 秒，站在里面每 1.5 秒回 1 点生命"
	cooldown = 18.0


func _activate() -> void:
	zone(player.global_position, 36.0, 6.0, SkillZone.Kind.HEAL, 1)
