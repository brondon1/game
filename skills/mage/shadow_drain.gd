extends MageSkill
## 暗影【灵魂汲取】：3 秒内每 0.5 秒抽取周围敌人的生命，每次打到敌人回 1 点血（最多回 3 点）。

var _timer := 0.0
var _healed := 0


func _init() -> void:
	display_name = "灵魂汲取"
	description = "3 秒内持续抽取周围敌人生命（每 0.5 秒 3 点），转成自己的血（最多 3 点）"
	cooldown = 14.0
	duration = 3.0


func _activate() -> void:
	_timer = 0.0
	_healed = 0


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_active() or not is_instance_valid(player):
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 0.5
	var targets := enemies_near(player.global_position, 90.0)
	for enemy in targets:
		enemy.take_damage(dmg(3))
		HitEffect.spawn(world(), enemy.global_position + Vector2(0, -6), Color("dc4a7b"), 3, 0.6)
	if not targets.is_empty() and _healed < 3 and int(_timer * 100) % 2 == 0:
		_healed += 1
		GameState.heal(1)
		HitEffect.spawn(world(), center(), Color("dc4a7b"), 6, 0.8)
