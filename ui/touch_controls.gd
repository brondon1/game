class_name TouchControls
extends Control
## 手机触屏操作：左半屏是浮动摇杆（手指按在哪里，摇杆就出现在哪里），右下角是攻击、技能、换枪、交互按钮，
## 右上角是暂停按钮，点小地图打开大地图。
## 按钮直接触发和键盘一样的输入动作（shoot、skill、switch_weapon……），摇杆按推动的幅度按下 move_* 动作，
## 所以玩家和菜单的脚本不用区分操作方式。只在有触摸屏的设备上显示。

## 当前是否在用触屏操作（玩家据此决定没有目标时枪口朝哪，HUD 据此调整布局）
static var active := false
## 在没有触摸屏的电脑上也显示（截图、调试用）
static var force := false

## 摇杆头最多能推多远（像素）
const STICK_RADIUS := 16.0
const DEAD_ZONE := 0.2
## 屏幕左边多宽的区域可以按出摇杆（占屏幕宽度的比例）
const STICK_AREA := 0.45
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

var _touch := -1
var _center := Vector2.ZERO
var _player: Player

@onready var stick_base: Sprite2D = %StickBase
@onready var stick_knob: Sprite2D = %StickKnob
@onready var attack_icon: Sprite2D = %AttackIcon
@onready var skill_button: TouchScreenButton = %SkillButton
@onready var swap_button: TouchScreenButton = %SwapButton
@onready var interact_button: TouchScreenButton = %InteractButton


func _ready() -> void:
	active = force or DisplayServer.is_touchscreen_available()
	visible = active
	set_process(active)
	set_process_input(active)
	if not active:
		return
	GameState.weapons_changed.connect(_refresh_weapon)
	_refresh_weapon()
	_reset_stick.call_deferred() # 等布局算出尺寸后再放到默认位置


func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
	interact_button.visible = _player != null and _player.can_interact()
	swap_button.visible = GameState.weapons.size() > 1
	if _player and _player.skill:
		var skill := _player.skill
		if skill.is_active():
			skill_button.modulate = Color("72d6ce")
		elif skill.is_ready():
			skill_button.modulate = Color.WHITE
		else:
			skill_button.modulate = Color(1, 1, 1, 0.4) # 冷却中变暗


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch == -1 and touch.position.x < size.x * STICK_AREA:
			_touch = touch.index
			_center = touch.position
			stick_base.position = _center
			stick_base.modulate.a = 1.0
			_move_stick(touch.position)
		elif not touch.pressed and touch.index == _touch:
			_reset_stick()
	elif event is InputEventScreenDrag and (event as InputEventScreenDrag).index == _touch:
		_move_stick((event as InputEventScreenDrag).position)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			# 暂停时收不到松手事件，先把摇杆收回来，免得恢复后角色自己往前走
			_reset_stick()
		NOTIFICATION_RESIZED:
			if _touch == -1 and is_node_ready():
				_reset_stick()


func _move_stick(pos: Vector2) -> void:
	var offset := (pos - _center).limit_length(STICK_RADIUS)
	stick_knob.position = offset
	var value := offset / STICK_RADIUS
	if value.length() < DEAD_ZONE:
		value = Vector2.ZERO
	_set_action(&"move_left", -value.x)
	_set_action(&"move_right", value.x)
	_set_action(&"move_up", -value.y)
	_set_action(&"move_down", value.y)


func _set_action(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


## 松手：摇杆回到左下角的默认位置（半透明），松开所有移动动作。
func _reset_stick() -> void:
	_touch = -1
	stick_base.position = Vector2(48, size.y - 48)
	stick_base.modulate.a = 0.5
	stick_knob.position = Vector2.ZERO
	for action in MOVE_ACTIONS:
		Input.action_release(action)


## 攻击按钮上画的是手上的武器。
func _refresh_weapon() -> void:
	var weapon := GameState.current_weapon()
	attack_icon.texture = weapon.texture if weapon else null
