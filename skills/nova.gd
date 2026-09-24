extends Skill
## 法师技能【元素新星】：清除身边的敌方子弹，并向四周放出一圈穿透弹。

const BULLET_SCENE := preload("res://weapons/bullet.tscn")

@export var bullet_count := 20
@export var damage := 5
@export var bullet_speed := 240.0
@export var bullet_range := 220.0
## 清除敌方子弹的半径
@export var clear_radius := 72.0


func _activate() -> void:
	var center := player.global_position + Vector2(0, -4)
	for node in get_tree().get_nodes_in_group("enemy_bullets"):
		var bullet := node as Bullet
		if bullet and bullet.global_position.distance_to(center) <= clear_radius:
			bullet.destroy()

	var bullet_damage := maxi(1, roundi(damage * GameState.damage_mult))
	for i in bullet_count:
		var bullet: Bullet = BULLET_SCENE.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.setup(Bullet.Team.PLAYER, center, TAU * i / bullet_count, bullet_speed, bullet_damage, bullet_range, true)
		bullet.modulate = Color(0.6, 1.2, 2.2) # 把黄色子弹染成青色，和敌人的红色子弹区分开

	SlashEffect.spawn(get_tree().current_scene, center, 0.0, clear_radius * 0.5, TAU, Color("73eff7"))
	Events.screen_shake.emit(3.0)
