extends Enemy
## 炸弹哥布林：和玩家保持距离，定时朝玩家当前位置抛炸弹。
## 炸弹落点会先出现红色预警圈，落地后爆炸——看到红圈就快跑。

const BOMB_SCENE := preload("res://enemies/bomb.tscn")

@export var preferred_distance := 120.0
@export var throw_interval := 2.6

var _timer := 0.0


func _ready() -> void:
	super()
	_timer = randf_range(1.2, throw_interval)


func _think(delta: float) -> Vector2:
	_timer -= delta
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if _timer <= 0.0 and dist < 220.0 and has_line_of_sight_to_player():
		_timer = throw_interval
		var bomb: Bomb = BOMB_SCENE.instantiate()
		bomb.setup(global_position, player.global_position)
		get_parent().add_child(bomb)
		Sound.play(Sound.THROW)
	if dist > preferred_distance + 30.0 or not has_line_of_sight_to_player():
		return chase_direction()
	if dist < preferred_distance - 30.0:
		return -to_player / maxf(dist, 0.001)
	return Vector2.ZERO
