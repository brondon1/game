extends Control
## 主菜单：选择角色，开始游戏。

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var record_label: Label = %RecordLabel
@onready var characters_box: HBoxContainer = %Characters
@onready var character_info: Label = %CharacterInfo


func _ready() -> void:
	start_button.pressed.connect(_start)
	quit_button.pressed.connect(get_tree().quit)
	quit_button.visible = not OS.has_feature("web") # 网页版不能退出
	if GameState.best_floor > 0:
		record_label.text = "最高纪录：第 %d 层 · 通关 %d 次" % [GameState.best_floor, GameState.wins]
	else:
		record_label.text = "准备好进入地牢了吗？"
	_build_character_buttons()
	start_button.grab_focus()
	Sound.play_music(Sound.MUSIC_DUNGEON)


func _build_character_buttons() -> void:
	var group := ButtonGroup.new()
	for character in GameState.characters:
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.icon = character.icon()
		button.expand_icon = true
		button.custom_minimum_size = Vector2(40, 40)
		button.tooltip_text = character.display_name
		button.button_pressed = character == GameState.character
		button.pressed.connect(_select.bind(character))
		characters_box.add_child(button)
	_select(GameState.character)


func _select(character: CharacterData) -> void:
	GameState.character = character
	var skill: Skill = character.skill_scene.instantiate()
	character_info.text = "%s　生命 %d · 护盾 %d · 能量 %d\n技能【%s】%s" % [
		character.display_name, character.max_hp, character.max_shield, character.max_energy,
		skill.display_name, skill.description]
	skill.free()


func _start() -> void:
	GameState.new_run()
	get_tree().change_scene_to_file("res://dungeon/dungeon.tscn")
