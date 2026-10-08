class_name CharacterData
extends Resource
## 可选角色：外观、初始属性、初始武器和技能。新增角色：新建一个 CharacterData 资源并加到 GameState.characters。
## texture 是横向排列的动画帧：前 4 帧待机，后 4 帧跑动（和 0x72 素材包的排列一致）。

const IDLE_FRAMES := 4
const WALK_FRAMES := 4

@export var display_name := "角色"
@export var texture: Texture2D
@export var max_hp := 6
@export var max_shield := 1
@export var max_energy := 180
@export var speed := 100.0
@export var starting_weapon: WeaponData
## 技能场景：根节点挂一个继承 Skill 的脚本
@export var skill_scene: PackedScene
## 可选技能（脚本路径，每个都继承 Skill）。填了的话一次带其中一个，在大厅和这个角色对话时切换；
## 没填就用 skill_scene。法师的技能按流派分，见 MageBranches。
@export var skill_options: PackedStringArray = []
## 贴图横向一共几帧（只有一帧的贴图填 1）
@export var hframes := 8
## 在大厅里和这个角色聊天时说的话（每次聊天换下一句）
@export var lines: PackedStringArray = []


## 现在的外观（法师会按流派换外观，见 GameState.character_texture()）
func look() -> Texture2D:
	return GameState.character_texture(self)


## 菜单里用的头像：动画的第一帧
func icon() -> Texture2D:
	var tex := look()
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(0, 0, tex.get_width() / hframes, tex.get_height())
	return atlas
