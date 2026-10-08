extends Control
## 主菜单：选择角色，开始游戏。

const SELECTED_TEXTURE := preload("res://assets/ui/button_selected.png")

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var record_label: Label = %RecordLabel
@onready var characters_box: HBoxContainer = %Characters
@onready var character_info: Label = %CharacterInfo
@onready var upgrade_button: Button = %UpgradeButton


func _ready() -> void:
	start_button.pressed.connect(_start)
	upgrade_button.pressed.connect(_upgrade)
	quit_button.pressed.connect(get_tree().quit)
	quit_button.visible = not (OS.has_feature("web") or OS.has_feature("ios")) # 网页版和 iOS 不能自己退出
	if GameState.best_floor > 0:
		record_label.text = "最高纪录：第 %d 层 · 通关 %d 次" % [GameState.best_floor, GameState.wins]
	else:
		record_label.text = "准备好进入地牢了吗？"
	_build_character_buttons()
	start_button.grab_focus()
	Sound.play_music(Sound.MUSIC_DUNGEON)


func _build_character_buttons() -> void:
	var group := ButtonGroup.new()
	# 选中的角色用金色描边的凹陷按钮
	var selected := StyleBoxTexture.new()
	selected.texture = SELECTED_TEXTURE
	selected.set_texture_margin_all(3)
	selected.set_content_margin_all(4)
	for character in GameState.characters:
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.icon = character.icon()
		button.expand_icon = true
		button.custom_minimum_size = Vector2(40, 40)
		button.add_theme_stylebox_override("pressed", selected)
		button.add_theme_stylebox_override("hover_pressed", selected)
		button.tooltip_text = character.display_name
		button.button_pressed = character == GameState.character
		button.pressed.connect(_select.bind(character))
		characters_box.add_child(button)
	_select(GameState.character)


func _select(character: CharacterData) -> void:
	GameState.character = character
	var skill: Skill = character.skill_scene.instantiate()
	var level := GameState.level_of(character)
	var bonus := GameState.level_bonus(character)
	var stats := "初始属性：生命 %d" % (character.max_hp + bonus.hp)
	if GameState.has_shield(character): # 只有骑士有护盾
		stats += " · 护盾 %d" % (character.max_shield + bonus.shield)
	stats += " · 能量 %d" % (character.max_energy + bonus.energy)
	character_info.text = "%s　Lv.%d · 经验 %d\n%s\n技能【%s】%s" % [
		character.display_name, level, GameState.xp_of(character), stats, skill.display_name, skill.description]
	_refresh_upgrade()
	skill.free()


## 升级按钮：花经验永久提升初始属性。经验不够或满级时按钮变灰。
func _refresh_upgrade() -> void:
	var character := GameState.character
	var level := GameState.level_of(character)
	if level >= GameState.MAX_LEVEL:
		upgrade_button.text = "已满级"
		upgrade_button.disabled = true
		return
	var cost := GameState.upgrade_cost(level)
	upgrade_button.disabled = not GameState.can_upgrade(character)
	upgrade_button.text = "升级：%s（%s %d 经验）" % [
		GameState.next_reward_text(character), "需要" if upgrade_button.disabled else "花费", cost]


func _upgrade() -> void:
	if GameState.upgrade(GameState.character):
		Sound.play(Sound.BUFF, 0.0, 0.0)
		_select(GameState.character)


func _start() -> void:
	GameState.new_run()
	get_tree().change_scene_to_file("res://dungeon/dungeon.tscn")
