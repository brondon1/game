extends MageSkill
## 火焰【火焰冲刺】：往移动方向冲一段（冲刺中无敌），走过的路留下一串火。

var _trail_timer := 0.0


func _init() -> void:
	display_name = "火焰冲刺"
	description = "冲刺一段距离（无敌），沿路留下燃烧 2.5 秒的火焰"
	cooldown = 5.0
	duration = 0.3


func _activate() -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO:
		dir = player.aim_direction
	player.start_dash(dir.normalized() * 300.0, duration)
	_trail_timer = 0.0


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_active() or not is_instance_valid(player):
		return
	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = 0.05
		zone(player.global_position, 14.0, 2.5, SkillZone.Kind.BURN, dmg(2))
