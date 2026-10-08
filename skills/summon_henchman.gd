extends Skill
## 狂战士技能【召唤小弟】：每次召唤一个蛮族小弟帮忙砍敌人，可以同时有好几个（超过上限时最早的那个退场）。

const MAX_HENCHMEN := 4


func _activate() -> void:
	var existing := get_tree().get_nodes_in_group(Henchman.GROUP)
	for i in existing.size() - (MAX_HENCHMEN - 1): # 节点按加入顺序排，前面的最老
		(existing[i] as Henchman).dismiss()
	var henchman := Henchman.new()
	henchman.owner_player = player
	# 在身边随机一个不在墙里的位置出现
	var spot := player.global_position
	for i in 8:
		var offset := Vector2.from_angle(randf() * TAU) * 18.0
		var query := PhysicsRayQueryParameters2D.create(player.global_position, player.global_position + offset * 1.5, Bullet.LAYER_WORLD)
		if player.get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			spot = player.global_position + offset
			break
	henchman.position = spot
	player.get_parent().add_child(henchman)
	Events.screen_shake.emit(2.0)
