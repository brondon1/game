extends MageSkill
## 火焰【陨石术】：在敌人最扎堆的地方先出现预警圈，0.6 秒后砸下陨石，大范围爆炸，地上留一片火。

const FALL_TIME := 0.6


func _init() -> void:
	display_name = "陨石术"
	description = "砸下一颗陨石：14 点范围伤害，落点燃烧 3 秒"
	cooldown = 9.0


func _activate() -> void:
	var spot := target_spot()
	var ring := sprite_fx("../bomb_ring.png", world(), spot)
	ring.modulate = Color(1, 0.5, 0.3)
	var rock := sprite_fx("meteor.png", world(), spot + Vector2(-60, -120))
	rock.z_index = 10
	var tween := rock.create_tween()
	tween.tween_property(rock, "position", spot + Vector2(0, -6), FALL_TIME).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		ring.queue_free()
		rock.queue_free()
		Explosion.spawn(rock.get_parent(), spot, 40.0, dmg(14), Bullet.Team.PLAYER)
		Events.screen_shake.emit(6.0)
		if is_instance_valid(player):
			zone(spot, 30.0, 3.0, SkillZone.Kind.BURN, dmg(2)))
