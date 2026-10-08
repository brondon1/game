extends MageSkill
## 机械师【机甲冲撞】：推进器全开往前猛冲（冲刺中无敌），撞飞路上的敌人。

var _hit: Array[Enemy] = []


func _init() -> void:
	display_name = "机甲冲撞"
	description = "往前猛冲（无敌），撞飞路上的敌人并造成 10 点伤害"
	cooldown = 6.0
	duration = 0.35


func _activate() -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO:
		dir = player.aim_direction
	player.start_dash(dir.normalized() * 340.0, duration)
	_hit.clear()
	Events.screen_shake.emit(2.0)


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_active() or not is_instance_valid(player):
		return
	HitEffect.spawn(world(), player.global_position, Color("ee8e2e"), 2, 0.5, true) # 推进器的火
	for enemy in enemies_near(player.global_position, 18.0):
		if enemy in _hit:
			continue
		_hit.append(enemy)
		enemy.take_damage(dmg(10), player.global_position.direction_to(enemy.global_position) * 2.5)
		Events.screen_shake.emit(3.0)
