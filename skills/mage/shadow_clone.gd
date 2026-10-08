extends MageSkill
## 暗影【暗影分身】：召唤一个半透明的分身跟在身边，自动朝敌人开火，持续 6 秒。

const TURRET_SCENE := preload("res://skills/turret.tscn")


func _init() -> void:
	display_name = "暗影分身"
	description = "召唤分身跟在身边一起开火（每 0.35 秒 3 点伤害），持续 6 秒"
	cooldown = 14.0


func _activate() -> void:
	var clone: Turret = TURRET_SCENE.instantiate()
	clone.fires_rockets = false
	clone.counts_as_turret = false
	clone.lifetime = 6.0
	clone.fire_interval = 0.35
	clone.damage = 3
	clone.follow = player
	clone.follow_offset = Vector2(-16, 2)
	clone.position = player.global_position + clone.follow_offset
	world().add_child(clone)
	clone.sprite.texture = player.sprite.texture
	clone.sprite.hframes = player.sprite.hframes
	clone.sprite.offset = Vector2(0, -player.sprite.texture.get_height() / 2.0 + 1.0)
	clone.sprite.self_modulate = Color(0.55, 0.35, 0.9, 0.7)
