extends Skill
## 工程师技能【部署炮台】：在脚下放一座会自动射击的炮台，持续一段时间。

const TURRET_SCENE := preload("res://skills/turret.tscn")


func _activate() -> void:
	var turret: Turret = TURRET_SCENE.instantiate()
	# 放在脚下偏下一点，免得被角色挡住；那里是墙的话就放在原地
	var spot := player.global_position + Vector2(0, 14)
	var query := PhysicsRayQueryParameters2D.create(player.global_position, spot + Vector2(0, 6), Bullet.LAYER_WORLD)
	if not player.get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		spot = player.global_position
	turret.position = spot
	player.get_parent().add_child(turret)
