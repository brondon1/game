extends MageSkill
## 女巫【魔法坩埚】：在脚下放一口坩埚 8 秒（回能量、回血、吐毒泡泡打敌人）。

func _init() -> void:
	display_name = "魔法坩埚"
	description = "放一口坩埚 8 秒：站在旁边回能量和生命（最多 3 点），坩埚吐毒泡泡打附近敌人"
	cooldown = 16.0


func _activate() -> void:
	var pot := Cauldron.new()
	pot.position = reach_point(player.global_position, Vector2.DOWN, 14.0, 6.0)
	world().add_child(pot)
