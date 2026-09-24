extends Skill
## 刺客技能【影袭】：瞬间冲向视线内最近的敌人，到达后对周围造成伤害，冲刺过程中无敌。
## 附近没有敌人时朝瞄准方向短冲。

@export var strike_damage := 12
@export var strike_radius := 30.0
@export var dash_speed := 520.0


func _activate() -> void:
	var target := player.find_aim_target()
	var dir := player.aim_direction
	var dist := 80.0
	if target:
		var to := target.global_position - player.global_position
		dir = to.normalized()
		dist = maxf(to.length() - 10.0, 0.0)
	var time := maxf(dist / dash_speed, 0.06)
	_active_left = time # 冲刺结束（_end）时出刀
	player.start_dash(dir * dash_speed, time)


func _end() -> void:
	if not is_instance_valid(player) or not player.is_inside_tree():
		return
	var center := player.global_position + Vector2(0, -4)
	var damage := maxi(1, roundi(strike_damage * GameState.damage_mult))
	var targets := get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("breakables")
	for node in targets:
		var target := node as Node2D
		if target is Enemy and not target.is_targetable():
			continue
		if target.global_position.distance_to(center) <= strike_radius + 6.0:
			target.take_damage(damage, center.direction_to(target.global_position) * 1.5)
	SlashEffect.spawn(get_tree().current_scene, center, player.aim_direction.angle(), strike_radius, TAU * 0.8, Color("e43b44"))
	HitEffect.spawn(player.get_parent(), center, Color("e43b44"), 10, 1.2)
	Events.screen_shake.emit(3.0)
