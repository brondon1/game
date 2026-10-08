extends MageSkill
## 潮汐【潮汐冲击】：向前推出一道浪，冲开敌人、冲掉子弹。

func _init() -> void:
	display_name = "潮汐冲击"
	description = "向前推出一道浪：6 点伤害并把敌人冲开，冲掉沿路子弹"
	cooldown = 6.0


func _activate() -> void:
	var wave := SkillMover.new()
	wave.texture = load(SKILL_SPRITES + "wave.png")
	wave.hframes = 2
	wave.velocity = player.aim_direction * 170.0
	wave.lifetime = 0.8
	wave.radius = 22.0
	wave.hit_damage = dmg(6)
	wave.push = 2.5
	wave.position = player.global_position + player.aim_direction * 12.0
	world().add_child(wave)
	Sound.play(Sound.THROW, -2.0)
