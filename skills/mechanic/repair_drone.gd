extends MageSkill
## 机械师【维修无人机】：无人机跟着飞 10 秒，每 2 秒回 1 点血（最多 3 点），并打掉飞到身边的子弹。

func _init() -> void:
	display_name = "维修无人机"
	description = "无人机跟飞 10 秒：每 2 秒回 1 点生命（最多 3 点），用电弧打掉靠近的子弹"
	cooldown = 16.0


func _activate() -> void:
	var drone := Drone.new()
	drone.mode = Drone.Mode.REPAIR
	drone.owner_player = player
	drone.lifetime = 10.0
	drone.position = center()
	world().add_child(drone)
