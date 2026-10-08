extends MageSkill
## 疾风【风墙】：面前一道风墙，把飞来的子弹反弹回去。

func _init() -> void:
	display_name = "风墙"
	description = "面前一道风墙，持续 4 秒，把敌人的子弹反弹回去（反弹后 4 点伤害）"
	cooldown = 8.0


func _activate() -> void:
	var wall := SkillBarrier.new()
	wall.texture = load(SKILL_SPRITES + "wind_wall.png")
	wall.reflect = true
	wall.reflect_damage = dmg(4)
	wall.facing = player.aim_direction
	wall.position = player.global_position + player.aim_direction * 26.0
	world().add_child(wall)
