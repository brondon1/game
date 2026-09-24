class_name CharacterData
extends Resource
## 可选角色：外观、初始属性、初始武器和技能。新增角色：新建一个 CharacterData 资源并加到 GameState.characters。
## texture 是横向排列的动画帧：前 4 帧待机，后 4 帧跑动（和 0x72 素材包的排列一致）。

const IDLE_FRAMES := 4
const WALK_FRAMES := 4

@export var display_name := "角色"
@export var texture: Texture2D
@export var max_hp := 6
@export var max_shield := 4
@export var max_energy := 180
@export var speed := 100.0
@export var starting_weapon: WeaponData
## 技能场景：根节点挂一个继承 Skill 的脚本
@export var skill_scene: PackedScene
## 贴图横向一共几帧（只有一帧的贴图填 1）
@export var hframes := 8


## 菜单里用的头像：动画的第一帧
func icon() -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0, 0, texture.get_width() / hframes, texture.get_height())
	return atlas
