extends Enemy
## 蝙蝠（小恶魔）：飞得快、血少，走 S 形路线扑向玩家。

var _t := 0.0


func _ready() -> void:
	super()
	_t = randf() * TAU
	_sprite_base_y -= 6.0 # 飞在半空中


func _think(delta: float) -> Vector2:
	_t += delta
	return chase_direction().rotated(sin(_t * 4.0) * 0.8)


## 逐帧动画之外，身体再上下飘一飘。
func _animate(delta: float, move_dir: Vector2) -> void:
	super(delta, move_dir)
	sprite.position.y = _sprite_base_y + sin(_t * 6.0) * 1.5
