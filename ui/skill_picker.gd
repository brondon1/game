class_name SkillPicker
extends CanvasLayer
## 技能选择面板：列出角色所有可选的技能（名字、效果、冷却），点"装备"带上其中一个。
## 法师上面多一排流派头像，点哪个流派就列出哪个流派的 3 个技能；装备时流派和技能一起换。
## 打开时暂停游戏，Esc 或"完成"关闭；换过技能的话关闭时 changed 为 true。

signal closed(changed: bool)

const GOLD := Color(0.98, 0.796, 0.243)

var character: CharacterData
## 法师正在看的流派（不一定是装备着的那个）
var _viewing := ""
var _changed := false

@onready var portrait: TextureRect = %Portrait
@onready var title: Label = %Title
@onready var equipped: Label = %Equipped
@onready var branches: HFlowContainer = %Branches
@onready var list: VBoxContainer = %List
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	hide()
	close_button.pressed.connect(close)


func open(ch: CharacterData) -> void:
	character = ch
	_changed = false
	_viewing = GameState.mage_branch
	_rebuild()
	show()
	get_tree().paused = true


func close() -> void:
	hide()
	closed.emit(_changed)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func _is_mage() -> bool:
	return GameState.is_mage(character)


func _rebuild() -> void:
	portrait.texture = character.icon()
	portrait.custom_minimum_size = portrait.texture.get_size() # 女巫的贴图比别人高，别被裁掉
	title.text = "%s · 选择技能" % character.display_name
	var current := GameState.create_skill(character)
	var prefix := MageBranches.branch_name(GameState.mage_branch) + " · " if _is_mage() else ""
	equipped.text = "已装备：%s%s" % [prefix, current.display_name]
	current.free()
	for child in branches.get_children() + list.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	branches.visible = _is_mage()
	if _is_mage():
		for b: Array in MageBranches.BRANCHES:
			_branch_button(b[0])
	var count := MageBranches.skill_count(_viewing) if _is_mage() else character.skill_options.size()
	for i in count:
		_skill_row(i)
	_focus.call_deferred()


## 流派头像按钮：正在看的流派按下去，装备着的流派名字是金色
func _branch_button(id: String) -> void:
	var button := Button.new()
	var atlas := AtlasTexture.new()
	var tex := MageBranches.texture(id)
	atlas.atlas = tex
	atlas.region = Rect2(0, 0, tex.get_width() / 8.0, tex.get_height())
	button.icon = atlas
	button.text = MageBranches.branch_name(id)
	button.toggle_mode = true
	button.button_pressed = id == _viewing
	if id == GameState.mage_branch:
		button.add_theme_color_override("font_color", GOLD)
		button.add_theme_color_override("font_pressed_color", GOLD)
	button.pressed.connect(func() -> void:
		_viewing = id
		Sound.play(Sound.CLICK, -6.0, 0.0)
		_rebuild.call_deferred())
	branches.add_child(button)


## 一行技能：名字和冷却、效果说明、"装备"按钮（已经带着的显示"已装备"）
func _skill_row(index: int) -> void:
	var skill := MageBranches.create_skill(_viewing, index) if _is_mage() else _option(index)
	var is_equipped := _equipped_index() == index and (not _is_mage() or _viewing == GameState.mage_branch)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = "%s　冷却 %d 秒" % [skill.display_name, roundi(skill.cooldown)]
	if is_equipped:
		name_label.add_theme_color_override("font_color", GOLD)
	text.add_child(name_label)
	var desc := Label.new()
	desc.text = skill.description
	desc.modulate.a = 0.75
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(300, 0)
	text.add_child(desc)
	row.add_child(text)
	var button := Button.new()
	button.custom_minimum_size = Vector2(64, 0)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.text = "已装备" if is_equipped else "装备"
	button.disabled = is_equipped
	button.pressed.connect(_equip.bind(index))
	row.add_child(button)
	list.add_child(row)
	skill.free()


func _option(index: int) -> Skill:
	return load(character.skill_options[index]).new()


func _equipped_index() -> int:
	return GameState.mage_skill_index() if _is_mage() else GameState.skill_choice(character)


func _equip(index: int) -> void:
	if _is_mage():
		GameState.set_mage_branch(_viewing)
		GameState.set_mage_skill(index)
	else:
		GameState.set_skill_choice(character, index)
	_changed = true
	Sound.play(Sound.BUFF, -4.0, 0.0)
	_rebuild.call_deferred()


func _focus() -> void:
	var buttons := list.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return not b.disabled)
	var target: Control = buttons[0] if not buttons.is_empty() else close_button
	if is_instance_valid(target) and target.is_inside_tree():
		target.grab_focus()
