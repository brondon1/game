extends MageSkill
## 疾风【龙卷风】：放出一个往前走的龙卷风，卷走沿路子弹，把敌人拖着走。

func _init() -> void:
	display_name = "龙卷风"
	description = "龙卷风往前推进 3 秒：卷走子弹，拖着敌人走，每 0.3 秒 3 点伤害"
	cooldown = 8.0


func _activate() -> void:
	var t := SkillMover.new()
	t.texture = load(SKILL_SPRITES + "tornado.png")
	t.hframes = 2
	t.velocity = player.aim_direction * 60.0
	t.lifetime = 3.0
	t.radius = 18.0
	t.hit_damage = dmg(3)
	t.tick = 0.3
	t.drag = true
	t.position = player.global_position + player.aim_direction * 16.0
	world().add_child(t)
