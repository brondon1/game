extends MageSkill
## 机械师【地雷阵】：身边撒一圈 5 颗地雷，敌人踩上就炸，地雷放 20 秒。

func _init() -> void:
	display_name = "地雷阵"
	description = "身边撒 5 颗地雷，敌人靠近就爆炸（10 点伤害），持续 20 秒"
	cooldown = 8.0


func _activate() -> void:
	for i in 5:
		var mine := MushroomMine.new()
		mine.texture = load(SKILL_SPRITES + "landmine.png")
		mine.hframes = 2
		mine.leaves_poison = false
		mine.blast_radius = 30.0
		mine.damage = dmg(10)
		var dir := Vector2.from_angle(TAU * i / 5.0 - PI / 2.0)
		mine.position = reach_point(player.global_position, dir, 26.0, 6.0)
		world().add_child(mine)
	Sound.play(Sound.THROW, -4.0)
