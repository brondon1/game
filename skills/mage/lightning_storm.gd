extends MageSkill
## 雷电【雷暴】：5 秒内每 0.4 秒自动劈一道闪电，在敌人之间连锁跳 3 次。

var _timer := 0.0


func _init() -> void:
	display_name = "雷暴"
	description = "5 秒内每 0.4 秒劈一道闪电（5 点伤害），连锁跳 3 次"
	cooldown = 12.0
	duration = 5.0


func _activate() -> void:
	_timer = 0.0


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_active() or not is_instance_valid(player):
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 0.4
	var targets := enemies_near(player.global_position, 170.0)
	if targets.is_empty():
		return
	var target: Enemy = targets.pick_random()
	var top := target.global_position + Vector2(randf_range(-10, 10), -90)
	Lightning._bolt(world(), top, target.global_position + Vector2(0, -4))
	target.take_damage(dmg(5))
	Lightning.chain(world(), target, dmg(5), 3, 70.0)
	Sound.play(Sound.ENEMY_SHOT, -8.0)
