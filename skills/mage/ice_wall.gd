extends MageSkill
## 冰霜【冰墙】：面前立一道冰墙挡子弹，持续 4 秒。

func _init() -> void:
	display_name = "冰墙"
	description = "面前立一道冰墙，挡住飞来的子弹，持续 4 秒"
	cooldown = 8.0


func _activate() -> void:
	var wall := SkillBarrier.new()
	wall.texture = load(SKILL_SPRITES + "ice_wall.png")
	wall.facing = player.aim_direction
	wall.position = player.global_position + player.aim_direction * 26.0
	world().add_child(wall)
	Sound.play(Sound.DEFLECT, -4.0)
