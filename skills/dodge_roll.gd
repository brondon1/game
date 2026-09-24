extends Skill
## 游侠技能【翻滚】：朝移动方向快速翻滚，翻滚过程中无敌。冷却很短，用来躲子弹。

@export var roll_speed := 320.0


func _activate() -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO:
		dir = player.aim_direction # 站着不动时朝瞄准方向翻滚
	player.start_dash(dir.normalized() * roll_speed, duration)
