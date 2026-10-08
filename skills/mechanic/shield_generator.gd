extends MageSkill
## 机械师【能量护盾发生器】：脚下放一个护盾装置 5 秒，圆罩挡掉所有飞进来的敌方子弹。

func _init() -> void:
	display_name = "护盾发生器"
	description = "放一个护盾装置 5 秒：半径 40 的圆罩挡掉所有飞进来的子弹"
	cooldown = 14.0


func _activate() -> void:
	var dome := zone(player.global_position, 40.0, 5.0, SkillZone.Kind.SHIELD)
	var device := sprite_fx("shield_generator.png", dome, Vector2(0, -3))
	device.z_index = 1
	Sound.play(Sound.BUFF, -4.0)
