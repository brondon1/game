extends MageSkill
## 机械师【攻击无人机】：放出 2 架无人机绕身飞 8 秒，自动扫射附近的敌人。

func _init() -> void:
	display_name = "攻击无人机"
	description = "2 架无人机绕身飞 8 秒，自动扫射附近敌人（每 0.25 秒 2 点伤害）"
	cooldown = 12.0


func _activate() -> void:
	for i in 2:
		var drone := Drone.new()
		drone.mode = Drone.Mode.ATTACK
		drone.owner_player = player
		drone.lifetime = 8.0
		drone.angle = PI * i
		drone.position = center()
		world().add_child(drone)
