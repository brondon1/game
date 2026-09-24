class_name HUD
extends CanvasLayer
## 游戏内界面：生命/护盾/能量条、楼层和金币、当前武器、Boss 血条、屏幕中央的提示文字。

var _message_tween: Tween

@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var shield_bar: ProgressBar = %ShieldBar
@onready var shield_label: Label = %ShieldLabel
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var energy_label: Label = %EnergyLabel
@onready var floor_label: Label = %FloorLabel
@onready var coin_label: Label = %CoinLabel
@onready var weapon_label: Label = %WeaponLabel
@onready var boss_panel: Control = %BossPanel
@onready var boss_bar: ProgressBar = %BossBar
@onready var message: Label = %Message


func _ready() -> void:
	_style_bar(hp_bar, Color("b13e53"))
	_style_bar(shield_bar, Color("94b0c2"))
	_style_bar(energy_bar, Color("41a6f6"))
	_style_bar(boss_bar, Color("ef7d57"))
	boss_panel.hide()
	message.modulate.a = 0.0
	GameState.stats_changed.connect(_refresh_stats)
	GameState.weapons_changed.connect(_refresh_weapon)
	Events.boss_health_changed.connect(_on_boss_health_changed)
	_refresh_stats()
	_refresh_weapon()


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
	floor_label.text = "第 %d / %d 层" % [GameState.current_floor, GameState.FINAL_FLOOR]
	coin_label.text = "金币 %d" % GameState.coins


func _refresh_weapon() -> void:
	var weapon := GameState.current_weapon()
	if weapon == null:
		weapon_label.text = ""
		return
	var text := "%s  能耗 %d" % [weapon.display_name, weapon.energy_cost]
	if GameState.weapons.size() > 1:
		var other := GameState.weapons[(GameState.weapon_index + 1) % GameState.weapons.size()]
		text += "\n[Q] 切换到 %s" % other.display_name
	weapon_label.text = text


func _on_boss_health_changed(hp: int, max_hp: int) -> void:
	boss_bar.max_value = max_hp
	boss_bar.value = hp
	boss_panel.visible = hp > 0


func _set_bar(bar: ProgressBar, label: Label, value: int, max_value: int) -> void:
	bar.max_value = max_value
	bar.value = value
	label.text = "%d/%d" % [value, max_value]


func _style_bar(bar: ProgressBar, color: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("1a1c2c")
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	bar.show_percentage = false
