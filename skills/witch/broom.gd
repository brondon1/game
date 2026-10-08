extends MageSkill
## 女巫【骑扫帚】：骑上扫帚飞 3 秒：移速 +80%，子弹打不到，一路往身后丢魔药炸弹。

var _broom: Sprite2D
var _drop_timer := 0.0


func _init() -> void:
	display_name = "骑扫帚"
	description = "骑扫帚飞 3 秒：移速 +80%、子弹打不到，沿路丢魔药炸弹（6 点伤害）"
	cooldown = 10.0
	duration = 3.0


func _activate() -> void:
	GameState.speed_mult += 0.8
	player.shield_for(duration)
	_broom = sprite_fx("broom.png", player, Vector2(-2, -2))
	_broom.z_index = -1
	player.sprite.position.y -= 4.0 # 飞起来一点
	_drop_timer = 0.2


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_active() or not is_instance_valid(player):
		return
	_broom.flip_h = player.sprite.flip_h
	_drop_timer -= delta
	if _drop_timer > 0.0:
		return
	_drop_timer = 0.4
	var spot := player.global_position
	var bomb := sprite_fx("../potion.png", world(), spot + Vector2(0, -4))
	bomb.modulate = Color(1.6, 0.6, 0.4)
	var tween := bomb.create_tween()
	tween.tween_property(bomb, "position:y", spot.y, 0.25)
	tween.tween_interval(0.25)
	tween.tween_callback(func() -> void:
		Explosion.spawn(bomb.get_parent(), spot, 22.0, dmg(6), Bullet.Team.PLAYER)
		bomb.queue_free())


func _end() -> void:
	GameState.speed_mult -= 0.8
	if is_instance_valid(_broom):
		_broom.queue_free()
	if is_instance_valid(player):
		player.sprite.position.y += 4.0
