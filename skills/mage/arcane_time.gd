extends MageSkill
## 奥术【时间减缓】：脚下展开一个时间结界，里面的敌人和敌方子弹都变慢，自己不受影响。

func _init() -> void:
	display_name = "时间减缓"
	description = "展开 4 秒时间结界：里面的敌人变慢，敌方子弹只剩 30% 的速度"
	cooldown = 12.0


func _activate() -> void:
	zone(player.global_position, 90.0, 4.0, SkillZone.Kind.TIME)
	Events.screen_shake.emit(2.0)
