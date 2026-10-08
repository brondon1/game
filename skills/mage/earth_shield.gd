extends MageSkill
## 大地【岩石护盾】：身边绕着 3 块石头，每块挡一次伤害，持续 8 秒。

var _stones: Array[Sprite2D] = []
var _spin := 0.0


func _init() -> void:
	display_name = "岩石护盾"
	description = "3 块石头绕身：每块挡一次伤害，持续 8 秒"
	cooldown = 14.0
	duration = 8.0


func _activate() -> void:
	player.damage_blocks = 3
	for i in 3:
		var stone := sprite_fx("stone.png", player, Vector2.ZERO)
		stone.z_index = 1
		_stones.append(stone)


func _physics_process(delta: float) -> void:
	super(delta)
	if _stones.is_empty() or not is_instance_valid(player):
		return
	_spin += delta * 4.0
	for i in _stones.size(): # 已经挡掉的石头隐藏
		_stones[i].visible = i < player.damage_blocks
		_stones[i].position = Vector2.from_angle(_spin + TAU * i / 3.0) * Vector2(14, 8) + Vector2(0, -6)


func _end() -> void:
	for stone in _stones:
		if is_instance_valid(stone):
			stone.queue_free()
	_stones.clear()
	if is_instance_valid(player):
		player.damage_blocks = 0
