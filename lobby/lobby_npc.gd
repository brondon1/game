class_name LobbyNpc
extends Area2D
## 大厅里站着的人：播放待机动画、朝向玩家，头上显示名字。
## 玩家走近后按 E（手机上点手形按钮）互动，由大厅决定打开什么（角色：聊天 / 升级 / 选角色；商人：商店）。
## 设置了 character 时外观和名字取自角色，否则用 display_name / texture / hframes（比如商人）。

signal talked(npc: LobbyNpc)

@export var character: CharacterData
@export var display_name := ""
@export var texture: Texture2D
@export var hframes := 1
## 走近时提示的动作，比如"对话""交易"
@export var action := "对话"
## false 时不画自己（比如书架：贴图由家具画，这里只负责互动）
@export var show_sprite := true

var _time := randf() * 4.0
var _player: Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel
@onready var prompt: Label = $Prompt


func _ready() -> void:
	if character:
		texture = character.look()
		hframes = character.hframes
		display_name = character.display_name
	sprite.texture = texture
	sprite.hframes = hframes
	sprite.visible = show_sprite
	sprite.position.y = -texture.get_height() / 2.0 + 1.0 # 脚踩在节点原点上
	name_label.text = display_name
	prompt.text = action if TouchControls.active else "[E] " + action
	prompt.hide()
	BlobShadow.add_to(self)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## 第一帧当头像（许愿池这类没有 CharacterData 的东西用）
func icon_texture() -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0, 0, texture.get_width() / float(hframes), texture.get_height())
	return atlas


## 角色换了外观（法师换流派）后刷新贴图
func refresh_look() -> void:
	texture = character.look()
	sprite.texture = texture


func _process(delta: float) -> void:
	_time += delta
	if sprite.hframes >= 4:
		sprite.frame = int(_time * 6.0) % 4 # 待机 4 帧（角色的动画条前 4 帧是待机）
	elif sprite.hframes == 2:
		sprite.frame = int(_time * 3.0) % 2 # 许愿池的水面一闪一闪
	if is_instance_valid(_player):
		sprite.flip_h = _player.global_position.x < global_position.x


func interact(_by: Player) -> void:
	talked.emit(self)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body
		body.add_interactable(self)
		prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.remove_interactable(self)
		prompt.hide()
