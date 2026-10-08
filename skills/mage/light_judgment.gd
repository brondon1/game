extends MageSkill
## 圣光【审判光柱】：天上落下 5 道光柱，依次砸在附近的敌人身上（先出预警圈）。

func _init() -> void:
	display_name = "审判光柱"
	description = "落下 5 道光柱，每道 10 点伤害"
	cooldown = 8.0


func _activate() -> void:
	var targets := nearest_enemies(player.global_position, 180.0, 5)
	var spots: Array[Vector2] = []
	for i in 5:
		if targets.is_empty():
			spots.append(player.global_position + player.aim_direction * (40.0 + i * 20.0))
		else:
			spots.append(targets[i % targets.size()].global_position)
	var tween := create_tween()
	for spot in spots:
		tween.tween_callback(_strike.bind(spot))
		tween.tween_interval(0.15)


func _strike(spot: Vector2) -> void:
	if not is_instance_valid(player):
		return
	var ring := sprite_fx("../bomb_ring.png", world(), spot)
	ring.modulate = Color(1.5, 1.3, 0.5)
	ring.scale = Vector2.ONE * 0.5
	var tween := ring.create_tween()
	tween.tween_interval(0.4)
	tween.tween_callback(func() -> void:
		var beam := Sprite2D.new()
		beam.texture = load(SKILL_SPRITES + "pillar.png")
		beam.hframes = 2
		beam.offset = Vector2(0, -36)
		beam.position = spot
		beam.z_index = 5
		beam.material = preload("res://common/unshaded.tres")
		ring.get_parent().add_child(beam)
		var fade := beam.create_tween()
		fade.tween_property(beam, "modulate:a", 0.0, 0.35)
		fade.tween_callback(beam.queue_free)
		for enemy in enemies_near(spot, 18.0):
			enemy.take_damage(dmg(10))
		HitEffect.spawn(ring.get_parent(), spot, Color("facb3e"), 8, 1.0)
		ring.queue_free())
