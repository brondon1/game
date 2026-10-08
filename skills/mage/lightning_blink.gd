extends MageSkill
## 雷电【雷霆闪现】：瞬移一段距离，起点和落点各炸一圈电。

func _init() -> void:
	display_name = "雷霆闪现"
	description = "瞬移 90 像素，起点和落点各放一圈电（6 点伤害，连锁 2 次）"
	cooldown = 5.0


func _activate() -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO:
		dir = player.aim_direction
	dir = dir.normalized()
	var from := player.global_position
	var to := reach_point(from, dir, 90.0)
	_burst(from)
	Lightning._bolt(world(), from + Vector2(0, -6), to + Vector2(0, -6))
	player.global_position = to
	player.shield_for(0.3)
	_burst(to)


func _burst(pos: Vector2) -> void:
	SlashEffect.spawn(world(), pos + Vector2(0, -4), 0.0, 18.0, TAU, Color("72d6ce"))
	for enemy in enemies_near(pos, 36.0):
		enemy.take_damage(dmg(6))
		Lightning.chain(world(), enemy, dmg(6), 2, 60.0)
