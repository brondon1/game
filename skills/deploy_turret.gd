extends Skill
## 女巫技能【奥术炮塔】：在脚下召唤一座发射跟踪火箭的炮塔，持续一段时间。
## 冷却比炮塔的持续时间短，所以场上可以同时有好几座；超过上限时最老的那座收起来。

const TURRET_SCENE := preload("res://skills/turret.tscn")
const MAX_TURRETS := 3


func _activate() -> void:
	var turret: Turret = TURRET_SCENE.instantiate()
	# 放在脚下偏下一点，免得被角色挡住；那里是墙的话就放在原地
	var spot := player.global_position + Vector2(0, 14)
	var query := PhysicsRayQueryParameters2D.create(player.global_position, spot + Vector2(0, 6), Bullet.LAYER_WORLD)
	if not player.get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		spot = player.global_position
	turret.position = spot
	var existing := player.get_tree().get_nodes_in_group(Turret.GROUP)
	for i in existing.size() - (MAX_TURRETS - 1): # 节点按加入顺序排，前面的最老
		(existing[i] as Turret).dismiss()
	player.get_parent().add_child(turret)
