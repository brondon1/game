extends MageSkill
## 圣光【圣光屏障】：3 秒无敌护罩，碰到护罩的子弹全部消失。

var _bubble: Sprite2D


func _init() -> void:
	display_name = "圣光屏障"
	description = "3 秒无敌护罩，碰到的子弹全部消失"
	cooldown = 14.0
	duration = 3.0


func _activate() -> void:
	player.shield_for(duration)
	_bubble = sprite_fx("bubble.png", player, Vector2(0, -8))
	_bubble.modulate = Color(1.6, 1.4, 0.6)
	_bubble.z_index = 2


func _physics_process(delta: float) -> void:
	super(delta)
	if is_active() and is_instance_valid(player):
		clear_bullets(center(), 14.0)


func _end() -> void:
	if is_instance_valid(_bubble):
		_bubble.queue_free()
