extends MageSkill
## 女巫【召唤使魔】：召唤一只黑猫使魔绕着自己飞 10 秒，自动打敌人、挡子弹。

func _init() -> void:
	display_name = "召唤使魔"
	description = "黑猫使魔绕身飞 10 秒：每 0.5 秒吐一颗魔法弹（3 点伤害），挡掉撞上的子弹"
	cooldown = 14.0


func _activate() -> void:
	var cat := Familiar.new()
	cat.owner_player = player
	cat.position = center()
	world().add_child(cat)
