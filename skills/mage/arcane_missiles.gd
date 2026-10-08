extends MageSkill
## 奥术【奥术飞弹】：0.8 秒内连发 8 颗会拐弯追敌人的飞弹。

const BULLET_SCENE := preload("res://weapons/bullet.tscn")

var _left := 0
var _timer := 0.0


func _init() -> void:
	display_name = "奥术飞弹"
	description = "连发 8 颗追踪飞弹，每颗 4 点伤害"
	cooldown = 6.0
	duration = 0.8


func _activate() -> void:
	_left = 8
	_timer = 0.0


func _physics_process(delta: float) -> void:
	super(delta)
	if _left <= 0 or not is_instance_valid(player):
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 0.1
	_left -= 1
	var bullet: Bullet = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	var angle := player.aim_direction.angle() + randf_range(-0.8, 0.8) # 散开发射，再拐回来追敌人
	bullet.setup(Bullet.Team.PLAYER, center(), angle, 200.0, dmg(4), 320.0)
	bullet.homing = 7.0
	bullet.modulate = Color(1.2, 0.6, 2.0)
	Sound.play(Sound.SHOOT, -10.0)
