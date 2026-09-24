extends Skill
## 狂战士技能【狂暴】：一段时间内伤害、攻速、移速大幅提升，角色变红。

@export var damage_bonus := 0.6
@export var fire_rate_bonus := 0.4
@export var speed_bonus := 0.25


func _activate() -> void:
	GameState.damage_mult += damage_bonus
	GameState.fire_rate_mult += fire_rate_bonus
	GameState.speed_mult += speed_bonus
	GameState.stats_changed.emit()
	player.sprite.self_modulate = Color(1.5, 0.6, 0.6)
	HitEffect.spawn(player.get_parent(), player.global_position + Vector2(0, -6), Color("e43b44"), 16, 1.2)
	Events.screen_shake.emit(3.0)


func _end() -> void:
	GameState.damage_mult -= damage_bonus
	GameState.fire_rate_mult -= fire_rate_bonus
	GameState.speed_mult -= speed_bonus
	GameState.stats_changed.emit()
	if is_instance_valid(player):
		player.sprite.self_modulate = Color.WHITE
