extends MageSkill
## 暗影【黑洞】：前方放一个黑洞，2 秒内吸住敌人、吞掉子弹，最后炸开。

func _init() -> void:
	display_name = "黑洞"
	description = "黑洞吸住敌人、吞掉子弹 2 秒，最后炸开（14 点伤害）"
	cooldown = 10.0


func _activate() -> void:
	var spot := reach_point(player.global_position, player.aim_direction, 70.0, 12.0)
	var hole := zone(spot, 60.0, 2.0, SkillZone.Kind.PULL)
	hole.tree_exiting.connect(func() -> void:
		Explosion.spawn(hole.get_parent(), spot, 44.0, dmg(14), Bullet.Team.PLAYER))
