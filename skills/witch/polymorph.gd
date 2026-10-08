extends MageSkill
## 女巫【变形术】：把最近的 3 个敌人变成青蛙 4 秒：不能攻击、只会原地蹦，受到的伤害 +50%。
## Boss 不会被变形，改成减速。

const FROG := preload("res://assets/sprites/skills/frog.png")
const TIME := 4.0


func _init() -> void:
	display_name = "变形术"
	description = "把最近的 3 个敌人变成青蛙 4 秒（不能攻击，受到伤害 +50%），Boss 改成减速"
	cooldown = 10.0


func _activate() -> void:
	for enemy in nearest_enemies(player.global_position, 150.0, 3):
		HitEffect.spawn(world(), enemy.global_position + Vector2(0, -6), Color("97da3f"), 10, 1.0, true)
		if enemy is Boss:
			enemy.apply_slow(3.0)
			continue
		enemy.apply_stun(TIME, Color.WHITE, true)
		enemy.sprite.visible = false
		var frog := Sprite2D.new()
		frog.texture = FROG
		frog.hframes = 2
		frog.offset = Vector2(0, -5)
		enemy.add_child(frog)
		var tween := frog.create_tween().set_loops(int(TIME / 0.5))
		tween.tween_callback(func() -> void: frog.frame = 1)
		tween.tween_property(frog, "position:y", -4.0, 0.15)
		tween.tween_property(frog, "position:y", 0.0, 0.15)
		tween.tween_callback(func() -> void: frog.frame = 0)
		tween.tween_interval(0.2)
		var undo := enemy.create_tween()
		undo.tween_interval(TIME)
		undo.tween_callback(func() -> void:
			frog.queue_free()
			enemy.sprite.visible = true
			HitEffect.spawn(enemy.get_parent(), enemy.global_position + Vector2(0, -6), Color("97da3f"), 6, 0.8, true))
	Sound.play(Sound.BUFF, -4.0)
