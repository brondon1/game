extends MageSkill
## 雷电【闪电链】：一道闪电打向最近的敌人，再在敌人之间连跳 6 次。

func _init() -> void:
	display_name = "闪电链"
	description = "闪电打向最近的敌人（9 点伤害），再连锁跳 6 次"
	cooldown = 4.0


func _activate() -> void:
	var targets := nearest_enemies(player.global_position, 170.0, 1)
	if targets.is_empty():
		return
	var first := targets[0]
	Lightning._bolt(world(), center(), first.global_position + Vector2(0, -4))
	first.take_damage(dmg(9))
	Lightning.chain(world(), first, dmg(9), 6, 80.0)
