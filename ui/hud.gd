class_name HUD
extends CanvasLayer
## 游戏内界面（0x72 素材包风格）：生命/护盾/能量条、楼层和金币、当前武器、技能、Boss 血条、屏幕中央的提示文字。

const BAR_TEXTURES := {
	"red": preload("res://assets/ui/bar_red.png"),
	"grey": preload("res://assets/ui/bar_grey.png"),
	"blue": preload("res://assets/ui/bar_blue.png"),
	"boss": preload("res://assets/ui/bar_boss.png"),
	"yellow": preload("res://assets/ui/bar_yellow.png"),
	"cyan": preload("res://assets/ui/bar_cyan.png"),
}
## 操作提示只在第一层开头显示一会儿（暂停菜单里一直能看到）
const CONTROLS_TIME := 10.0
const COIN_FPS := 8.0

var _message_tween: Tween
var _player: Player
var _skill_styles := {}
var _skill_state := ""
var _time := 0.0

@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var shield_bar: ProgressBar = %ShieldBar
@onready var shield_label: Label = %ShieldLabel
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var energy_label: Label = %EnergyLabel
@onready var floor_label: Label = %FloorLabel
@onready var coin_icon: TextureRect = %CoinIcon
@onready var coin_label: Label = %CoinLabel
@onready var weapon_icon: TextureRect = %WeaponIcon
@onready var weapon_label: Label = %WeaponLabel
@onready var cost_icon: TextureRect = %CostIcon
@onready var cost_label: Label = %CostLabel
@onready var swap_label: Label = %SwapLabel
@onready var boss_panel: Control = %BossPanel
@onready var boss_bar: ProgressBar = %BossBar
@onready var message: Label = %Message
@onready var minimap: Minimap = %Minimap
@onready var skill_label: Label = %SkillLabel
@onready var skill_bar: ProgressBar = %SkillBar
@onready var controls: Label = %Controls


func _ready() -> void:
	hp_bar.add_theme_stylebox_override("fill", bar_fill("red"))
	shield_bar.add_theme_stylebox_override("fill", bar_fill("grey"))
	energy_bar.add_theme_stylebox_override("fill", bar_fill("blue"))
	boss_bar.add_theme_stylebox_override("fill", bar_fill("boss"))
	for key in ["yellow", "cyan", "grey"]:
		_skill_styles[key] = bar_fill(key)
	coin_icon.texture = coin_icon.texture.duplicate() # 每个 HUD 自己转自己的金币
	boss_panel.hide()
	message.modulate.a = 0.0
	controls.visible = GameState.current_floor == 1
	GameState.stats_changed.connect(_refresh_stats)
	GameState.weapons_changed.connect(_refresh_weapon)
	Events.boss_health_changed.connect(_on_boss_health_changed)
	Events.message.connect(show_message)
	_refresh_stats()
	_refresh_weapon()


## 进度条填充样式：九宫格贴图，左右上下各留出底框的 2 像素
static func bar_fill(color: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = BAR_TEXTURES[color]
	style.texture_margin_left = 2
	style.texture_margin_right = 2
	style.texture_margin_top = 3
	style.texture_margin_bottom = 3
	return style


func _process(delta: float) -> void:
	_time += delta
	(coin_icon.texture as AtlasTexture).region.position.x = 8.0 * (int(_time * COIN_FPS) % 4)
	if controls.visible and _time > CONTROLS_TIME:
		controls.modulate.a = maxf(0.0, 0.8 - (_time - CONTROLS_TIME))
		controls.visible = controls.modulate.a > 0.0
	_update_skill()


func show_message(text: String) -> void:
	message.text = text
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_property(message, "modulate:a", 1.0, 0.2)
	_message_tween.tween_interval(1.2)
	_message_tween.tween_property(message, "modulate:a", 0.0, 0.4)


func _refresh_stats() -> void:
	_set_bar(hp_bar, hp_label, GameState.hp, GameState.max_hp)
	_set_bar(shield_bar, shield_label, GameState.shield, GameState.max_shield)
	_set_bar(energy_bar, energy_label, GameState.energy, GameState.max_energy)
	floor_label.text = "第 %d/%d 层" % [GameState.current_floor, GameState.FINAL_FLOOR]
	coin_label.text = str(GameState.coins)


func _refresh_weapon() -> void:
	var weapon := GameState.current_weapon()
	weapon_icon.texture = weapon.texture if weapon else null
	weapon_label.text = weapon.display_name if weapon else ""
	cost_icon.visible = weapon != null and not weapon.is_melee
	cost_label.text = "" if weapon == null else ("近战" if weapon.is_melee else str(weapon.energy_cost))
	swap_label.visible = GameState.weapons.size() > 1
	if swap_label.visible:
		var other := GameState.weapons[(GameState.weapon_index + 1) % GameState.weapons.size()]
		swap_label.text = "[Q] 切换到 %s" % other.display_name


## 技能冷却条：冷却中灰色，可用时黄色，生效中青色。
func _update_skill() -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
	if _player == null or _player.skill == null:
		return
	var skill := _player.skill
	skill_bar.value = skill.charge()
	var state := "grey"
	if skill.is_active():
		skill_label.text = "%s 中" % skill.display_name
		skill_label.modulate = Color("72d6ce")
		state = "cyan"
	elif skill.is_ready():
		skill_label.text = "[空格] %s" % skill.display_name
		skill_label.modulate = Color("facb3e")
		state = "yellow"
	else:
		skill_label.text = "[空格] %s" % skill.display_name
		skill_label.modulate = Color(1, 1, 1, 0.5)
	if state != _skill_state: # 只在状态变化时换样式，免得每帧触发重新布局
		_skill_state = state
		skill_bar.add_theme_stylebox_override("fill", _skill_styles[state])


func _on_boss_health_changed(hp: int, max_hp: int) -> void:
	boss_bar.max_value = max_hp
	boss_bar.value = hp
	boss_panel.visible = hp > 0


func _set_bar(bar: ProgressBar, label: Label, value: int, max_value: int) -> void:
	bar.max_value = max_value
	bar.value = value
	label.text = "%d/%d" % [value, max_value]
