extends MageSkill
## 剧毒【毒蘑菇】：身边种 3 个毒蘑菇，敌人走近就炸开放毒。

func _init() -> void:
	display_name = "毒蘑菇"
	description = "种 3 个毒蘑菇：敌人靠近就爆炸（6 点伤害）并留下毒雾"
	cooldown = 10.0


func _activate() -> void:
	for i in 3:
		var mine := MushroomMine.new()
		mine.damage = dmg(6)
		var offset := Vector2.from_angle(TAU * i / 3.0 - PI / 2.0) * 20.0
		mine.position = reach_point(player.global_position, offset.normalized(), 20.0, 6.0)
		world().add_child(mine)
