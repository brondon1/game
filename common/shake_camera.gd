extends Camera2D
## 会震动的相机：任何地方发出 Events.screen_shake(强度) 都能触发。

@export var decay := 30.0

var _strength := 0.0


func _ready() -> void:
	Events.screen_shake.connect(func(strength: float) -> void: _strength = maxf(_strength, strength))


func _process(delta: float) -> void:
	if _strength > 0.0:
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _strength
		_strength = move_toward(_strength, 0.0, decay * delta)
	else:
		offset = Vector2.ZERO
