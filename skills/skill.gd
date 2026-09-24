class_name Skill
extends Node
## 角色技能基类。子类重写 _activate()；有持续时间的技能在 _end() 里撤销效果。
## 冷却从技能效果结束后才开始计算。

@export var display_name := "技能"
@export_multiline var description := ""
@export var cooldown := 8.0
## 持续时间（秒），0 表示瞬发
@export var duration := 0.0
@export var sound: AudioStream

var player: Player

var _cooldown_left := 0.0
var _active_left := 0.0


func is_ready() -> bool:
	return _cooldown_left <= 0.0 and _active_left <= 0.0


func is_active() -> bool:
	return _active_left > 0.0


## 冷却进度：0 = 刚用完，1 = 可以使用。
func charge() -> float:
	if is_active():
		return 0.0
	return 1.0 - _cooldown_left / cooldown if cooldown > 0.0 else 1.0


func try_activate() -> bool:
	if not is_ready():
		return false
	_cooldown_left = cooldown
	_active_left = duration
	Sound.play(sound, 0.0, 0.0)
	_activate()
	if duration <= 0.0:
		_end()
	return true


func _physics_process(delta: float) -> void:
	if _active_left > 0.0:
		_active_left -= delta
		if _active_left <= 0.0:
			_end()
	elif _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func _activate() -> void:
	pass


func _end() -> void:
	pass
