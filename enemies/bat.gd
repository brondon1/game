extends Enemy
## 蝙蝠：飞得快、血少，扇着翅膀走 S 形路线扑向玩家。

var _t := 0.0


func _ready() -> void:
	super()
	_t = randf() * TAU


func _think(delta: float) -> Vector2:
	_t += delta
	return chase_direction().rotated(sin(_t * 4.0) * 0.8)


## 飞行动画：两帧扇翅膀，身体上下飘，不做走路的挤压。
func _animate(_delta: float, _move_dir: Vector2) -> void:
	sprite.frame = int(_t * 12.0) % 2
	sprite.position.y = _sprite_base_y + sin(_t * 6.0) * 1.5
