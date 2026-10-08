class_name LobbyNpc
extends Area2D
## 大厅里站着的角色：播放待机动画、朝向玩家，头上显示名字。
## 玩家走近后按 E（手机上点手形按钮）对话，由大厅打开对话框（聊天 / 升级 / 选这个角色）。

signal talked(npc: LobbyNpc)

@export var character: CharacterData

var _time := randf() * 4.0
var _player: Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel
@onready var prompt: Label = $Prompt


func _ready() -> void:
	sprite.texture = character.texture
	sprite.hframes = character.hframes
	sprite.position.y = -character.texture.get_height() / 2.0 + 1.0 # 脚踩在节点原点上
	name_label.text = character.display_name
	prompt.text = "对话" if TouchControls.active else "[E] 对话"
	prompt.hide()
	BlobShadow.add_to(self)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_time += delta
	if sprite.hframes >= 8:
		sprite.frame = int(_time * 6.0) % 4 # 待机 4 帧
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
